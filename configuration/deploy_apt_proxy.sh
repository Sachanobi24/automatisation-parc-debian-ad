#!/bin/bash
# =============================================================================
# deploy_apt_proxy.sh
# Déploiement de la configuration proxy apt-cacher-ng sur des VMs étudiantes
# Prérequis : clé SSH configurée + sudoers sans mot de passe sur les cibles
# =============================================================================

set -euo pipefail

# --- Configuration -----------------------------------------------------------
PROXY_IP="10.0.100.10"
PROXY_PORT="3142"
PROXY_CONF="/etc/apt/apt.conf.d/01proxy"
SSH_USER="${SSH_USER:-debian}"
SSH_KEY="${HOME}/.ssh/id_ed25519"     # Clé SSH (générée par deploy-cles.sh)
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes -i ${SSH_KEY}"

# Liste des VMs cibles — lues depuis hosts.txt (une IP/hostname par ligne)
HOSTS_FILE="${1:-hosts.txt}"

# --- Couleurs ----------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Fonctions ---------------------------------------------------------------

log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

print_banner() {
    echo ""
    echo "=============================================="
    echo "  Déploiement proxy apt-cacher-ng"
    echo "  Cible : http://${PROXY_IP}:${PROXY_PORT}"
    echo "  VMs   : ${#VMS[@]} machine(s)"
    echo "=============================================="
    echo ""
}

# Vérifie que le fichier hosts existe et n'est pas vide
check_hosts_file() {
    if [[ ! -f "$HOSTS_FILE" ]]; then
        log_error "Fichier introuvable : ${HOSTS_FILE}"
        exit 1
    fi

    mapfile -t VMS < <(grep -v '^\s*#' "$HOSTS_FILE" | grep -v '^\s*$')

    if [[ ${#VMS[@]} -eq 0 ]]; then
        log_error "Aucune VM trouvée dans ${HOSTS_FILE}"
        exit 1
    fi
}

# Vérifie que la clé SSH existe
check_ssh_key() {
    if [[ ! -f "$SSH_KEY" ]]; then
        log_error "Clé SSH introuvable : ${SSH_KEY}"
        log_info  "Générer avec : ssh-keygen -t ed25519 -f ${SSH_KEY} -N \"\""
        log_info  "Puis copier  : ssh-copy-id -i ${SSH_KEY}.pub ${SSH_USER}@<VM>"
        exit 1
    fi
}

# Vérifie que le serveur apt-cacher-ng est joignable
check_proxy_reachable() {
    log_info "Vérification de la disponibilité du cache ${PROXY_IP}:${PROXY_PORT}..."
    if curl -s --connect-timeout 3 "http://${PROXY_IP}:${PROXY_PORT}" > /dev/null 2>&1; then
        log_ok "Serveur apt-cacher-ng joignable."
    else
        log_error "Impossible de joindre http://${PROXY_IP}:${PROXY_PORT}. Abandon."
        exit 1
    fi
}

# Télécharge la clé GPG OnlyOffice une seule fois sur la machine de déploiement
prepare_onlyoffice_gpg() {
    if [[ ! -s /tmp/onlyoffice-apt.gpg ]]; then
        log_info "Téléchargement de la clé GPG OnlyOffice..."
        if curl -fsSL https://download.onlyoffice.com/GPG-KEY-ONLYOFFICE \
            | gpg --dearmor > /tmp/onlyoffice-apt.gpg 2>/dev/null; then
            log_ok "Clé GPG OnlyOffice téléchargée."
        else
            log_warn "Impossible de télécharger la clé GPG OnlyOffice — les VMs avec ce dépôt échoueront."
            rm -f /tmp/onlyoffice-apt.gpg
        fi
    fi
}

# Vérifie que sudo fonctionne sans mot de passe sur la VM
check_sudoers() {
    local vm_ip="$1"
    ssh $SSH_OPTS "${SSH_USER}@${vm_ip}" "sudo -n true" 2>/dev/null
}

# Déploie la config proxy et lance apt update sur une VM
deploy_to_vm() {
    local vm_ip="$1"
    local proxy_line="Acquire::http::Proxy \"http://${PROXY_IP}:${PROXY_PORT}\";"

    log_info "Déploiement sur ${vm_ip}..."

    # Vérification SSH
    if ! ssh $SSH_OPTS "${SSH_USER}@${vm_ip}" "true" 2>/dev/null; then
        log_error "${vm_ip} → SSH inaccessible"
        return 1
    fi

    # Vérification sudo sans mot de passe
    if ! check_sudoers "$vm_ip"; then
        log_error "${vm_ip} → sudo sans mot de passe non configuré"
        return 1
    fi

    # Déploiement de la config proxy
    if ! ssh $SSH_OPTS "${SSH_USER}@${vm_ip}" \
        "echo '${proxy_line}' | sudo tee ${PROXY_CONF} > /dev/null" 2>/dev/null; then
        log_error "${vm_ip} → échec écriture de ${PROXY_CONF}"
        return 1
    fi

    # Correction du miroir si besoin (plusserver → deb.debian.org)
    ssh $SSH_OPTS "${SSH_USER}@${vm_ip}" \
        "sudo sed -i 's|mirror.plusserver.com/debian|deb.debian.org/debian|g' /etc/apt/sources.list" 2>/dev/null || true

    # Ajout de la clé GPG OnlyOffice si le dépôt est présent sur la VM
    if ssh $SSH_OPTS "${SSH_USER}@${vm_ip}" \
        "grep -rq 'onlyoffice' /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null" 2>/dev/null; then

        if [[ -s /tmp/onlyoffice-apt.gpg ]]; then
            scp $SSH_OPTS /tmp/onlyoffice-apt.gpg "${SSH_USER}@${vm_ip}:/tmp/onlyoffice-apt.gpg" 2>/dev/null && \
            ssh $SSH_OPTS "${SSH_USER}@${vm_ip}" \
                "sudo mv /tmp/onlyoffice-apt.gpg /usr/share/keyrings/onlyoffice.gpg && \
                 sudo chmod 644 /usr/share/keyrings/onlyoffice.gpg && \
                 echo 'deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main' | \
                 sudo tee /etc/apt/sources.list.d/onlyoffice.list > /dev/null" 2>/dev/null || true
        fi
    fi

    # Lancement de apt update
    if ! ssh $SSH_OPTS "${SSH_USER}@${vm_ip}" \
        "sudo apt-get update -qq" 2>/dev/null; then
        log_warn "${vm_ip} → proxy configuré mais apt update a échoué"
        return 1
    fi

    log_ok "${vm_ip} → proxy configuré et apt update OK"
    return 0
}

# --- Main --------------------------------------------------------------------

check_hosts_file
check_ssh_key
print_banner
check_proxy_reachable
prepare_onlyoffice_gpg

SUCCESS=0
FAIL=0

for vm in "${VMS[@]}"; do
    if deploy_to_vm "$vm"; then
        (( SUCCESS++ )) || true
    else
        (( FAIL++ )) || true
    fi
done

echo ""
echo "=============================================="
log_ok "Succès : ${SUCCESS}/${#VMS[@]} VM(s)"
if [[ $FAIL -gt 0 ]]; then
    log_warn "Échecs  : ${FAIL}/${#VMS[@]} VM(s)"
fi
echo "=============================================="
echo ""
