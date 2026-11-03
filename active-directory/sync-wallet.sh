#!/bin/bash
USER_NAME="$PAM_USER"

UID_U=$(id -u "$USER_NAME" 2>/dev/null)
[ -z "$UID_U" ] && exit 0
[ "$UID_U" -lt 500000 ] && exit 0

GID_U=$(id -g "$USER_NAME" 2>/dev/null)
WALLET_DIR="/home/${USER_NAME}/.local/share/kwalletd"
WALLET_SHARE="//srv-fichiers/profiles/${USER_NAME}/kwalletd"

mkdir -p "$WALLET_DIR"
mountpoint -q "$WALLET_DIR" && exit 0

mount -t cifs "$WALLET_SHARE" "$WALLET_DIR" \
  -o "sec=krb5,cruid=${UID_U},uid=${UID_U},gid=${GID_U},\
file_mode=0600,dir_mode=0700,vers=3.0" \
  >> /var/log/sync-wallet.log 2>&1

exit 0
