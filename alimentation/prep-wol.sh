#!/bin/bash
# Active le Wake-on-LAN (persistant, via NetworkManager) et affiche la MAC sur stdout.
# Lance en root sur chaque poste.

IFACE=$(ip -o -4 route show default | awk '{print $5; exit}')
if [ -z "$IFACE" ]; then
  echo "ERREUR: interface introuvable" >&2
  exit 1
fi

# Connexion NetworkManager active sur cette interface
CONN=$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: -v i="$IFACE" '$2==i{print $1; exit}')
if [ -n "$CONN" ]; then
  # Arme le WOL "magic packet" (s'applique au prochain redemarrage)
  nmcli connection modify "$CONN" 802-3-ethernet.wake-on-lan magic
fi

# Affiche la MAC de l'interface (recuperee par le script de preparation)
cat /sys/class/net/"$IFACE"/address
