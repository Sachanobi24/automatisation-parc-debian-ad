#!/bin/bash
# Reveille les postes via Wake-on-LAN, en lisant macs.txt (genere par preparer-wol.sh).
# Necessite l'outil wakeonlan : sudo apt install wakeonlan
# Envoie le paquet magique sur l'adresse de broadcast du /24 de chaque poste.

command -v wakeonlan >/dev/null 2>&1 || {
  echo "Outil manquant. Installe-le : sudo apt install wakeonlan"
  exit 1
}

n=0
while read -r mac ip <&3; do
  [[ -z "$mac" || "$mac" == \#* ]] && continue
  # Broadcast du sous-reseau /24 : dernier octet remplace par 255
  bcast="${ip%.*}.255"
  echo "Reveil de $ip ($mac) -> broadcast $bcast"
  wakeonlan -i "$bcast" "$mac"
  n=$((n+1))
done 3< macs.txt

echo "=== $n paquets magiques envoyes ==="
