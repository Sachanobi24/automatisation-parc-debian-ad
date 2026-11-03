#!/bin/bash
# Renomme chaque poste selon la convention de nommage, installe et configure
# zabbix-agent (v1), puis cree/met a jour le host cote serveur Zabbix via l'API.
# Prerequis : acces-ssh/deploy-cles.sh PUIS acces-ssh/deploy-sudo.sh.
# Le token API n'est JAMAIS ecrit dans le script : export ZABBIX_API_TOKEN=...

# ---- A adapter avant le lancement ----
SSH_USER="${SSH_USER:-debian}"
HOSTS_FILE="${HOSTS_FILE:-hosts.txt}"

ZABBIX_AGENT_SERVER="10.0.100.30"
ZABBIX_API_URL="http://10.0.100.30/zabbix/api_jsonrpc.php"
ZABBIX_API_TOKEN="${ZABBIX_API_TOKEN:?Definir le token : export ZABBIX_API_TOKEN=...}"
ZABBIX_GROUP_NAME="Machines Debian_Labo"
ZABBIX_TEMPLATE_NAME="Linux by Zabbix agent"
# ---------------------------------------

# Calcule le hostname selon l'IP
# Convention : debian-pc{dernier_octet}baie{vlan/10} sauf VLAN 126 -> salleA
get_hostname() {
  local ip="$1"
  local vlan octet suffix
  vlan=$(echo "$ip" | cut -d. -f3)
  octet=$(echo "$ip" | cut -d. -f4)
  case "$vlan" in
    10)  suffix="baie1" ;;
    20)  suffix="baie2" ;;
    30)  suffix="baie3" ;;
    40)  suffix="baie4" ;;
    50)  suffix="baie5" ;;
    70)  suffix="baie7" ;;
    126) suffix="salleA" ;;
    *)   suffix="vlan${vlan}" ;;
  esac
  echo "debian-pc${octet}${suffix}"
}

api_call() {
  wget -q -O - \
    --header="Content-Type: application/json-rpc" \
    --header="Authorization: Bearer ${ZABBIX_API_TOKEN}" \
    --post-data="{\"jsonrpc\":\"2.0\",\"method\":\"$1\",\"params\":$2,\"id\":1}" \
    "$ZABBIX_API_URL"
}

echo ">>> Preparation API Zabbix (groupe + modele)..."

GROUP_ID=$(api_call "hostgroup.get" "{\"filter\":{\"name\":[\"${ZABBIX_GROUP_NAME}\"]}}" | grep -oP '"groupid":"\K[0-9]+' | head -1)
if [ -z "$GROUP_ID" ]; then
  echo "  Groupe '${ZABBIX_GROUP_NAME}' absent, creation..."
  GROUP_ID=$(api_call "hostgroup.create" "{\"name\":\"${ZABBIX_GROUP_NAME}\"}" | grep -oP '"groupids":\["\K[0-9]+' | head -1)
fi
if [ -z "$GROUP_ID" ]; then
  echo "  ERREUR : impossible de recuperer/creer le groupe. Verifie URL/token."
  exit 1
fi
echo "  Groupe ID = $GROUP_ID"

TEMPLATE_ID=$(api_call "template.get" "{\"filter\":{\"host\":[\"${ZABBIX_TEMPLATE_NAME}\"]}}" | grep -oP '"templateid":"\K[0-9]+' | head -1)
if [ -z "$TEMPLATE_ID" ]; then
  echo "  ERREUR : modele '${ZABBIX_TEMPLATE_NAME}' introuvable."
  exit 1
fi
echo "  Modele ID = $TEMPLATE_ID"
echo

OK=0
KO=0

while read -r poste <&3; do
  [[ -z "$poste" || "$poste" == \#* ]] && continue
  echo "=== $poste ==="

  if ! timeout 3 bash -c "echo > /dev/tcp/$poste/22" 2>/dev/null; then
    echo "  injoignable, on passe"
    KO=$((KO+1))
    continue
  fi

  HOSTNAME_CIBLE=$(get_hostname "$poste")
  echo "  hostname cible : $HOSTNAME_CIBLE"

  RESULT=$(timeout 120 ssh -n "${SSH_USER}@$poste" "
    export DEBIAN_FRONTEND=noninteractive
    export NEEDRESTART_MODE=a
    export NEEDRESTART_SUSPEND=1

    # Renommage du poste
    sudo hostnamectl set-hostname ${HOSTNAME_CIBLE}
    echo '127.0.1.1 ${HOSTNAME_CIBLE}' | sudo tee -a /etc/hosts > /dev/null

    # Nettoyage Zabbix anterieur
    sudo systemctl stop zabbix-agent zabbix-agent2 2>/dev/null || true
    sudo systemctl disable zabbix-agent zabbix-agent2 2>/dev/null || true
    sudo apt-get purge -y zabbix-agent zabbix-agent2 zabbix-release 2>/dev/null || true
    sudo rm -f /etc/apt/sources.list.d/zabbix.list /etc/apt/sources.list.d/zabbix.sources
    sudo rm -rf /etc/zabbix
    sudo rm -f /etc/apt/trusted.gpg.d/zabbix* /usr/share/keyrings/zabbix*

    # Proxy apt
    APT_OPTS=()
    if ! timeout 2 bash -c 'echo > /dev/tcp/10.0.100.10/3142' 2>/dev/null; then
      APT_OPTS=(-o Acquire::http::Proxy=false -o Acquire::https::Proxy=false)
    fi

    sudo apt-get update -qq \"\${APT_OPTS[@]}\" || true
    sudo apt-get install --reinstall -o Dpkg::Options::=\"--force-confmiss\" -y \"\${APT_OPTS[@]}\" zabbix-agent

    sudo sed -i \"s|^Server=.*|Server=${ZABBIX_AGENT_SERVER}|\"             /etc/zabbix/zabbix_agentd.conf
    sudo sed -i \"s|^ServerActive=.*|ServerActive=${ZABBIX_AGENT_SERVER}|\" /etc/zabbix/zabbix_agentd.conf
    sudo sed -i \"s|^Hostname=.*|Hostname=${HOSTNAME_CIBLE}|\"              /etc/zabbix/zabbix_agentd.conf

    sudo systemctl enable --now zabbix-agent
    sudo systemctl restart zabbix-agent

    echo 'OK'
  " 2>/dev/null)

  if [ "$RESULT" != "OK" ]; then
    echo "  erreur pendant l'installation de l'agent"
    KO=$((KO+1))
    continue
  fi
  echo "  agent installe et demarre"

  EXISTING_ID=$(api_call "host.get" "{\"filter\":{\"host\":[\"${HOSTNAME_CIBLE}\"]}}" | grep -oP '"hostid":"\K[0-9]+' | head -1)

  if [ -n "$EXISTING_ID" ]; then
    api_call "host.update" "{\"hostid\":\"${EXISTING_ID}\",\"interfaces\":[{\"type\":1,\"main\":1,\"useip\":1,\"ip\":\"${poste}\",\"dns\":\"\",\"port\":\"10050\"}]}" >/dev/null
    echo "  host Zabbix mis a jour (id $EXISTING_ID)"
  else
    api_call "host.create" "{\"host\":\"${HOSTNAME_CIBLE}\",\"interfaces\":[{\"type\":1,\"main\":1,\"useip\":1,\"ip\":\"${poste}\",\"dns\":\"\",\"port\":\"10050\"}],\"groups\":[{\"groupid\":\"${GROUP_ID}\"}],\"templates\":[{\"templateid\":\"${TEMPLATE_ID}\"}]}" >/dev/null
    echo "  host Zabbix cree ($HOSTNAME_CIBLE)"
  fi

  OK=$((OK+1))

done 3< "$HOSTS_FILE"

echo
echo "=== Termine : $OK reussis, $KO en echec ==="
