#!/bin/bash
# Deploie sur chaque poste de hosts.txt :
#   1. le script notify-shutdown.sh dans /usr/local/bin/ (transfert via ssh+tee)
#   2. la tache cron dans /etc/cron.d/auto-shutdown (notification a 18h25, extinction a 18h30, lun-ven)
# Prerequis : deploy-cles.sh (cles SSH) PUIS deploy-sudo.sh (sudo NOPASSWD).

SSH_USER="${SSH_USER:-debian}"
HOSTS_FILE="${HOSTS_FILE:-hosts.txt}"

OK=0
KO=0

# La boucle lit hosts.txt sur le descripteur 3, pour laisser stdin (fd 0)
# disponible pour ssh (sinon ssh consomme le fichier et un seul poste est traite).
while read -r poste <&3; do
  [[ -z "$poste" || "$poste" == \#* ]] && continue
  echo "=== $poste ==="

  # Test de joignabilite du port SSH (via bash, pas besoin de netcat)
  if ! timeout 3 bash -c "echo > /dev/tcp/$poste/22" 2>/dev/null; then
    echo "  injoignable, on passe"
    KO=$((KO+1))
    continue
  fi

  # 1. Envoyer le script : son contenu passe par le stdin du ssh, tee l'ecrit
  # 2. Installer libnotify + creer la tache cron
  if ssh "${SSH_USER}@$poste" 'sudo tee /usr/local/bin/notify-shutdown.sh > /dev/null && sudo chmod +x /usr/local/bin/notify-shutdown.sh' < "$(dirname "$0")/notify-shutdown.sh" \
     && ssh -n "${SSH_USER}@$poste" 'sudo apt-get install -y libnotify-bin && echo "25 18 * * 1-5 root /usr/local/bin/notify-shutdown.sh" | sudo tee /etc/cron.d/auto-shutdown > /dev/null'; then
    echo "  OK"
    OK=$((OK+1))
  else
    echo "  erreur pendant le deploiement"
    KO=$((KO+1))
  fi

done 3< "$HOSTS_FILE"

echo "=== Termine : $OK reussis, $KO en echec ==="
