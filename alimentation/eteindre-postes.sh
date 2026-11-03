#!/bin/bash
# Eteint immediatement tous les postes JOIGNABLES de hosts.txt.
# Prerequis : cles SSH (deploy-cles.sh) + sudo NOPASSWD (deploy-sudo.sh).

# Confirmation : action impactante (eteint tout le parc)
SSH_USER="${SSH_USER:-debian}"
HOSTS_FILE="${HOSTS_FILE:-hosts.txt}"

read -r -p "Eteindre TOUS les postes de hosts.txt maintenant ? (oui/non) " rep
[ "$rep" = "oui" ] || { echo "Annule."; exit 0; }

OK=0
KO=0

while read -r poste <&3; do
  [[ -z "$poste" || "$poste" == \#* ]] && continue
  echo "=== $poste ==="

  # On saute les postes injoignables (deja eteints, par ex.)
  if ! timeout 3 bash -c "echo > /dev/tcp/$poste/22" 2>/dev/null; then
    echo "  injoignable, on passe"
    KO=$((KO+1))
    continue
  fi

  # Ordre d'extinction. La connexion se coupe quand le poste s'eteint,
  # donc on n'analyse pas le code de retour de ssh.
  ssh -n -o ConnectTimeout=5 "${SSH_USER}@$poste" 'sudo shutdown -h now' 2>/dev/null
  echo "  ordre d'extinction envoye"
  OK=$((OK+1))

done 3< "$HOSTS_FILE"

echo "=== Termine : $OK ordres envoyes, $KO injoignables ==="
