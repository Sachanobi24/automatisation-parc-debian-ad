#!/bin/bash

# Nettoyer PAM_USER des caractères invisibles (retour chariot, espaces)
USER_NAME=$(echo "$PAM_USER" | tr -d '\r\n[:space:]')

# Ignorer les utilisateurs systeme
UID_U=$(id -u "${USER_NAME}" 2>/dev/null)
[ -z "$UID_U" ] && exit 0
[ "$UID_U" -lt 500000 ] && exit 0

SUDOERS_FILE="/etc/sudoers.d/${USER_NAME}"

# Ne pas ecraser si deja configure
[ -f "$SUDOERS_FILE" ] && exit 0

# Attendre que SSSD ait resolu les groupes AD (max 10s)
TRIES=0
while [ $TRIES -lt 10 ]; do
    GROUPES=$(id -Gn "${USER_NAME}" 2>/dev/null)
    if echo "$GROUPES" | grep -qwiE "GROUPE_PROFS|GROUPE_CLASSE1|GROUPE_CLASSE2"; then
        break
    fi
    sleep 1
    TRIES=$((TRIES+1))
done

# Fallback via getent si SSSD toujours pas pret
if ! echo "$GROUPES" | grep -qwiE "GROUPE_PROFS|GROUPE_CLASSE1|GROUPE_CLASSE2"; then
    GROUPES=$(getent group | awk -F: -v u="$USER_NAME" '$4 ~ u {print $1}' | tr '\n' ' ')
fi

echo "$(date) $USER_NAME groupes=$GROUPES" >> /var/log/configurer-sudo.log

if echo "$GROUPES" | grep -qwi "GROUPE_PROFS"; then
    # PROFS : sudo complet
    {
        printf '# Sudo complet pour %s (GROUPE_PROFS)\n' "$USER_NAME"
        printf '%s ALL=(ALL:ALL) ALL\n' "$USER_NAME"
    } > "$SUDOERS_FILE"

elif echo "$GROUPES" | grep -qwi "GROUPE_CLASSE1" || echo "$GROUPES" | grep -qwi "GROUPE_CLASSE2"; then
    # ELEVES CLASSE1 / CLASSE2 : sudo limite
    {
        printf '# Sudo limite pour %s (eleve)\n\n' "$USER_NAME"
        printf 'Cmnd_Alias SERVICES = /usr/bin/systemctl start, \\\n'
        printf '\t/usr/bin/systemctl stop, \\\n'
        printf '\t/usr/bin/systemctl restart, \\\n'
        printf '\t/usr/bin/systemctl reload, \\\n'
        printf '\t/usr/bin/systemctl status, \\\n'
        printf '\t/usr/bin/systemctl enable, \\\n'
        printf '\t/usr/bin/systemctl disable\n\n'
        printf 'Cmnd_Alias PAQUETS = /usr/bin/apt install, \\\n'
        printf '\t/usr/bin/apt update, \\\n'
        printf '\t/usr/bin/apt upgrade, \\\n'
        printf '\t/usr/bin/apt remove, \\\n'
        printf '\t/usr/bin/apt autoremove, \\\n'
        printf '\t/usr/bin/apt show, \\\n'
        printf '\t/usr/bin/apt list, \\\n'
        printf '\t/usr/bin/apt search, \\\n'
        printf '\t/usr/bin/dpkg -i, \\\n'
        printf '\t/usr/bin/dpkg -l\n\n'
        printf 'Cmnd_Alias RESEAU = /usr/bin/ip, \\\n'
        printf '\t/sbin/ip, \\\n'
        printf '\t/bin/ping, \\\n'
        printf '\t/usr/bin/ping, \\\n'
        printf '\t/usr/sbin/traceroute, \\\n'
        printf '\t/usr/bin/traceroute, \\\n'
        printf '\t/usr/bin/nmap, \\\n'
        printf '\t/usr/sbin/nmap, \\\n'
        printf '\t/usr/bin/tcpdump, \\\n'
        printf '\t/usr/sbin/tcpdump, \\\n'
        printf '\t/usr/bin/ss, \\\n'
        printf '\t/bin/ss, \\\n'
        printf '\t/usr/sbin/iptables, \\\n'
        printf '\t/sbin/iptables, \\\n'
        printf '\t/usr/sbin/ip6tables, \\\n'
        printf '\t/sbin/ifconfig, \\\n'
        printf '\t/usr/sbin/ifconfig\n\n'
        printf 'Cmnd_Alias LOGS = /usr/bin/journalctl, \\\n'
        printf '\t/bin/journalctl, \\\n'
        printf '\t/usr/bin/tail, \\\n'
        printf '\t/usr/bin/cat /var/log/*, \\\n'
        printf '\t/bin/cat /var/log/*, \\\n'
        printf '\t/usr/bin/grep /var/log/, \\\n'
        printf '\t/bin/grep /var/log/\n\n'
        printf '%s ALL=(ALL) NOPASSWD: SERVICES\n' "$USER_NAME"
        printf '%s ALL=(ALL) NOPASSWD: PAQUETS\n' "$USER_NAME"
        printf '%s ALL=(ALL) NOPASSWD: RESEAU\n' "$USER_NAME"
        printf '%s ALL=(ALL) NOPASSWD: LOGS\n' "$USER_NAME"
    } > "$SUDOERS_FILE"
fi

# Securiser et logger
if [ -f "$SUDOERS_FILE" ]; then
    chmod 440 "$SUDOERS_FILE"
    echo "$(date) OK sudoers cree pour ${USER_NAME}" >> /var/log/configurer-sudo.log
else
    echo "$(date) AUCUN groupe sudo reconnu pour ${USER_NAME}" >> /var/log/configurer-sudo.log
fi
