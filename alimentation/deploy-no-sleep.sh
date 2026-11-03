#!/bin/bash
# Desactive la mise en veille et la veille profonde (suspend + hibernation)
# sur chaque poste de hosts.txt, en masquant les cibles systemd concernees.
# Prerequis : cles SSH (deploy-cles.sh) + sudo NOPASSWD (deploy-sudo.sh).

SSH_USER="${SSH_USER:-debian}"
HOSTS_FILE="${HOSTS_FILE:-hosts.txt}"

OK=0
KO=0

while read -r poste <&3; do
  [[ -z "$poste" || "$poste" == \#* ]] && continue
  echo "=== $poste ==="

  # Test de joignabilite du port SSH
  if ! timeout 3 bash -c "echo > /dev/tcp/$poste/22" 2>/dev/null; then
    echo "  injoignable, on passe"
    KO=$((KO+1))
    continue
  fi

  # Masque les 4 cibles de veille (suspend, hibernate, hybrid, sleep)
  if ssh -n "${SSH_USER}@$poste" \
       'sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target' \
       >/dev/null 2>&1; then
    echo "  OK - veille desactivee"
    OK=$((OK+1))
  else
    echo "  erreur"
    KO=$((KO+1))
  fi

done 3< "$HOSTS_FILE"

echo "=== Termine : $OK reussis, $KO en echec ==="
