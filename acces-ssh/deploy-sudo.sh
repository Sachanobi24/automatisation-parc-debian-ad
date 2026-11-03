#!/bin/bash
# Active sudo SANS mot de passe pour l'utilisateur d'administration
# sur chaque poste JOIGNABLE de hosts.txt.
# Les postes injoignables sont ignores : le deploiement continue sur les autres.
# "ssh -t" : sudo demandera le mot de passe une fois par poste.

SSH_USER="${SSH_USER:-debian}"
HOSTS_FILE="${HOSTS_FILE:-hosts.txt}"

OK=0
KO=0

while read -r poste <&3; do
  [[ -z "$poste" || "$poste" == \#* ]] && continue
  echo "=== $poste ==="

  # Si le poste ne repond pas, on le saute et on continue
  if ! timeout 3 bash -c "echo > /dev/tcp/$poste/22" 2>/dev/null; then
    echo "  injoignable, on passe"
    KO=$((KO+1))
    continue
  fi

  if ssh -t -o ConnectTimeout=5 "${SSH_USER}@$poste" \
       "echo '${SSH_USER} ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/${SSH_USER}-nopasswd > /dev/null && echo '  sudo NOPASSWD configure'"; then
    OK=$((OK+1))
  else
    echo "  erreur"
    KO=$((KO+1))
  fi

done 3< "$HOSTS_FILE"

echo "=== Termine : $OK reussis, $KO injoignables/echecs ==="
