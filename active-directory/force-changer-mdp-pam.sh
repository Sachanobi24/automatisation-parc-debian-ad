#!/bin/bash
# ============================================================
# force-changer-mdp-pam.sh
# Appele par PAM (pam_exec) a l'ouverture de session.
# Si l'utilisateur n'a pas encore change son mot de passe
# (attribut AD 'info' different de 'mdp_changed'), installe un
# lanceur KDE qui ouvrira changer-mdp.py au demarrage de sa session.
# ============================================================

exec >> /var/log/force-changer-mdp.log 2>&1
echo "=== $(date) USER=$PAM_USER ==="

USER_NAME="$PAM_USER"
UID_MIN=500000   # plage d'UID attribuee par SSSD aux comptes du domaine

UID_U=$(id -u "${USER_NAME}" 2>/dev/null)
[ -z "$UID_U" ] && exit 0
[ "$UID_U" -lt "$UID_MIN" ] && exit 0

# Mot de passe du compte de service (lecture LDAP), stocke dans un
# fichier lisible uniquement par root : /etc/samba/credentials-ldap
SVC_PASS=$(grep "^password=" /etc/samba/credentials-ldap | cut -d= -f2-)
AD_SERVER="10.0.100.20"
BASE_DN="DC=exemple,DC=local"
BIND_DN="svc-montage@EXEMPLE.LOCAL"
ENV_DIR="/home/${USER_NAME}/.config/plasma-workspace/env"
LANCEUR="${ENV_DIR}/force-changer-mdp.sh"

# Lecture de l'attribut 'info' dans l'AD
FLAG=$(ldapsearch -H "ldap://${AD_SERVER}" \
    -D "${BIND_DN}" -w "${SVC_PASS}" \
    -b "${BASE_DN}" \
    "(sAMAccountName=${USER_NAME})" info 2>/dev/null | grep "^info:" | awk '{print $2}')

echo "Flag AD = '${FLAG}'"

if [ "$FLAG" = "mdp_changed" ]; then
    echo "Mot de passe deja change pour ${USER_NAME} - skip"
    if [ -f "$LANCEUR" ]; then
        rm -f "$LANCEUR"
        echo "Lanceur residuel supprime"
    fi
    exit 0
fi

# Premiere connexion : attendre le home, puis installer le lanceur KDE
TRIES=0
while [ ! -d "/home/${USER_NAME}" ] && [ $TRIES -lt 15 ]; do
    sleep 1
    TRIES=$((TRIES+1))
done
[ ! -d "/home/${USER_NAME}" ] && echo "ERREUR : home introuvable" && exit 1

mkdir -p "${ENV_DIR}"

cat > "${LANCEUR}" << 'ENVSCRIPT_EOF'
#!/bin/bash
(
    sleep 5
    export DISPLAY=:0
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
    /usr/bin/python3 /usr/local/bin/changer-mdp.py
) &
ENVSCRIPT_EOF

GROUPE_PRINCIPAL=$(id -gn "${USER_NAME}")
chmod 755 "${LANCEUR}"
chown -R "${USER_NAME}:${GROUPE_PRINCIPAL}" "${ENV_DIR}"
chown "${USER_NAME}:${GROUPE_PRINCIPAL}" "/home/${USER_NAME}/.config/plasma-workspace"
chown "${USER_NAME}:${GROUPE_PRINCIPAL}" "/home/${USER_NAME}/.config"

echo "Lanceur installe pour ${USER_NAME}"
echo "=== Fin script ==="
exit 0
