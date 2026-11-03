#!/bin/bash
# ============================================================
# monter-classe.sh
# Monte les partages reseau (CIFS/Samba) de l'utilisateur a
# l'ouverture de session. Appele par PAM (pam_exec) : la variable
# PAM_USER contient le nom de l'utilisateur qui se connecte.
#
#   ~/personnel  -> partage personnel (users$/<utilisateur>)
#   ~/echange    -> partage commun a tous les utilisateurs du domaine
#   ~/classes    -> partage de la classe de l'eleve (selon son groupe AD)
#   ~/classe1, ~/classe2, ~/profs -> montes pour les professeurs
# ============================================================

exec >> /var/log/monter-classe.log 2>&1
echo "=== $(date) USER=$PAM_USER ==="

USER_NAME="$PAM_USER"
MOUNT_BASE="/home/${USER_NAME}"
SRV="//srv-fichiers"
CREDS="/etc/samba/credentials-ldap"
UID_MIN=500000   # plage d'UID attribuee par SSSD aux comptes du domaine

# Ignorer les utilisateurs systeme / locaux
UID_U=$(id -u "${USER_NAME}" 2>/dev/null)
[ -z "$UID_U" ] && exit 0
[ "$UID_U" -lt "$UID_MIN" ] && exit 0

# Attendre que pam_mkhomedir cree le home (max 10 secondes)
TRIES=0
while [ ! -d "$MOUNT_BASE" ] && [ $TRIES -lt 10 ]; do
    sleep 1
    TRIES=$((TRIES+1))
    echo "Attente home ($TRIES/10)..."
done
[ ! -d "$MOUNT_BASE" ] && echo "ERREUR : home introuvable" && exit 1

GID_U=$(id -g "${USER_NAME}" 2>/dev/null)
OPTS="credentials=${CREDS},vers=3.0,uid=${UID_U},gid=${GID_U},file_mode=0664,dir_mode=0775"

# monter <partage> <point_de_montage> <libelle>
monter() {
    mkdir -p "$2"
    if mount -t cifs "${SRV}/$1" "$2" -o "${OPTS}"; then
        echo "$3 monte"
    else
        echo "ERREUR montage $3"
    fi
}

# Demonter les residus eventuels de sessions precedentes
for d in echange classes classe1 classe2 profs personnel; do
    umount -l "${MOUNT_BASE}/${d}" 2>/dev/null
done

# --- Lecteur personnel ---
monter "users\$/${USER_NAME}" "${MOUNT_BASE}/personnel" "Personnel"

# Rediriger "Documents" (KDE) vers le lecteur personnel reseau
XDG_CONF="${MOUNT_BASE}/.config/user-dirs.dirs"
if [ -f "$XDG_CONF" ]; then
    sed -i "s|^XDG_DOCUMENTS_DIR=.*|XDG_DOCUMENTS_DIR=\"${MOUNT_BASE}/personnel\"|" "$XDG_CONF"
else
    mkdir -p "${MOUNT_BASE}/.config"
    echo "XDG_DOCUMENTS_DIR=\"${MOUNT_BASE}/personnel\"" > "$XDG_CONF"
fi

# --- Lecteur d'echange (tous les utilisateurs du domaine) ---
monter "echange" "${MOUNT_BASE}/echange" "Echange"

# --- Lecteurs de classe selon le groupe AD ---
GROUPES=$(id -Gn "${USER_NAME}" 2>/dev/null)
echo "Groupes : $GROUPES"

if echo "$GROUPES" | grep -qw "groupe_classe1"; then
    # Eleve classe 1 -> acces a classe1 uniquement
    monter "classe1" "${MOUNT_BASE}/classes" "Classe 1"

elif echo "$GROUPES" | grep -qw "groupe_classe2"; then
    # Eleve classe 2 -> acces a classe2 uniquement
    monter "classe2" "${MOUNT_BASE}/classes" "Classe 2"

elif echo "$GROUPES" | grep -qw "groupe_profs"; then
    # Professeur -> acces a classe1, classe2 ET profs
    monter "classe1" "${MOUNT_BASE}/classe1" "Classe 1 (prof)"
    monter "classe2" "${MOUNT_BASE}/classe2" "Classe 2 (prof)"
    monter 'profs$'  "${MOUNT_BASE}/profs"   "Profs"

else
    echo "Aucun groupe classe reconnu pour $USER_NAME"
fi

echo "=== Fin script ==="
exit 0
