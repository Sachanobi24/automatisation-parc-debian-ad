#!/bin/bash
# A LANCER PENDANT QUE LES POSTES SONT ALLUMES.
# 1. Active le Wake-on-LAN sur la carte reseau de chaque poste (persistant).
# 2. Collecte les adresses MAC dans macs.txt (utilise par rallumer-postes.sh).
# Prerequis : cles SSH + sudo NOPASSWD.

SSH_USER="${SSH_USER:-debian}"
HOSTS_FILE="${HOSTS_FILE:-hosts.txt}"

> macs.txt          # vide / cree le fichier
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

  # Pousser le helper, puis l'executer (il renvoie la MAC sur stdout)
  ssh "${SSH_USER}@$poste" 'sudo tee /usr/local/bin/prep-wol.sh > /dev/null && sudo chmod +x /usr/local/bin/prep-wol.sh' < "$(dirname "$0")/prep-wol.sh"
  mac=$(ssh -n "${SSH_USER}@$poste" 'sudo /usr/local/bin/prep-wol.sh' 2>/dev/null)

  if [ -n "$mac" ]; then
    echo "$mac $poste" >> macs.txt
    echo "  MAC $mac - WOL active"
    OK=$((OK+1))
  else
    echo "  echec"
    KO=$((KO+1))
  fi

done 3< "$HOSTS_FILE"

echo "=== Termine : $OK prepares, $KO injoignables/echecs ==="
echo "--- Contenu de macs.txt ---"
cat macs.txt
