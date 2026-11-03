#!/bin/bash
# Depose la cle SSH publique sur tous les postes de hosts.txt.
# - Genere une paire de cles UNIQUEMENT si elle n'existe pas (pas d'ecrasement).
# - Utilise -f -i pour contourner le bug "scratch_dir" de ssh-copy-id.
# A lancer UNE fois. Demande le mot de passe debian une fois par poste.

# 1. Generer une paire de cles seulement si absente
SSH_USER="${SSH_USER:-debian}"
HOSTS_FILE="${HOSTS_FILE:-hosts.txt}"

if [ ! -f ~/.ssh/id_ed25519.pub ]; then
  echo "Generation d'une paire de cles..."
  ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
fi

# 2. Copier la cle sur chaque poste (-f = saute le filtrage qui plante)
while read -r poste; do
  [[ -z "$poste" || "$poste" == \#* ]] && continue
  echo "=== $poste ==="
  ssh-copy-id -f -i ~/.ssh/id_ed25519.pub "${SSH_USER}@$poste"
done < "$HOSTS_FILE"

echo "=== Cles deployees ==="
