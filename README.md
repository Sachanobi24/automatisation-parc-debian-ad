# Automatisation d'un parc Debian intégré à Active Directory

Collection de scripts **Bash** et **Python** pour déployer, configurer, superviser et piloter à distance un parc de postes **Debian / KDE** intégrés à un domaine **Active Directory** (SSSD + Samba), dans un contexte de salle informatique pédagogique.

> ⚠️ **Dépôt anonymisé.** Les adresses IP, noms de domaine, noms de serveurs, groupes et jetons d'API sont fictifs (`10.0.x.x`, `exemple.local`, `srv-fichiers`, `groupe_classe1`…). Il faut les adapter à votre infrastructure avant tout usage.

## Ce que fait le projet

| Besoin | Solution |
|---|---|
| Administrer des dizaines de postes sans y aller physiquement | Déploiement par **SSH** (clés + sudo sans mot de passe) sur une liste d'hôtes |
| Garder un parc homogène | Configuration du **proxy apt-cacher-ng**, désactivation de la mise en veille |
| Surveiller l'état des machines | Installation de **zabbix-agent** + création automatique des hôtes via l'**API Zabbix** |
| Réduire la consommation | **Extinction automatique** en fin de journée avec notification à l'utilisateur |
| Gérer l'allumage / l'extinction du parc | **Wake-on-LAN** et extinction à distance |
| Intégrer les postes à l'AD | Montage automatique des **partages Samba** par groupe, **sudo** adapté au profil, **changement de mot de passe forcé** à la première connexion |

## Structure

```
.
├── hosts.txt.example            # liste des postes (à copier en hosts.txt)
├── acces-ssh/
│   ├── deploy-cles.sh           # génère/dépose la clé SSH sur tous les postes
│   └── deploy-sudo.sh           # sudo NOPASSWD pour le compte d'administration
├── configuration/
│   └── deploy_apt_proxy.sh      # proxy apt-cacher-ng + dépôts
├── supervision/
│   └── deploy-zabbix.sh         # agent Zabbix + enregistrement via l'API
├── alimentation/
│   ├── deploy-no-sleep.sh       # désactive veille / hibernation
│   ├── deploy-cron.sh           # déploie l'extinction auto (cron 18h25 → arrêt 18h30)
│   ├── notify-shutdown.sh       # notification graphique puis shutdown programmé
│   ├── preparer-wol.sh          # active le WOL et collecte les MAC (macs.txt)
│   ├── prep-wol.sh              # helper exécuté sur chaque poste par preparer-wol.sh
│   ├── rallumer-postes.sh       # envoie les paquets magiques
│   └── eteindre-postes.sh       # extinction immédiate (avec confirmation)
└── active-directory/
    ├── monter-classe.sh         # montage CIFS des partages à l'ouverture de session (PAM)
    ├── configurer-sudo.sh       # fichier sudoers par utilisateur selon son groupe AD (PAM)
    ├── sync-wallet.sh           # synchronise le portefeuille KDE sur le serveur (Kerberos)
    ├── force-changer-mdp-pam.sh # détecte la 1re connexion et installe le lanceur (PAM)
    └── changer-mdp.py           # interface zenity de changement de mot de passe
```

## Prérequis

- Poste d'administration Linux avec `ssh`, `wget`, `wakeonlan` (pour le WOL).
- Postes cibles Debian avec SSH activé et un compte d'administration (par défaut `debian`, modifiable via `SSH_USER`).
- Pour la partie AD : `sssd`, `samba-common-bin`, `cifs-utils`, `ldap-utils`, `zenity`, KDE Plasma.
- Pour la supervision : un serveur Zabbix avec un **token API** (créé dans l'interface Zabbix).

## Utilisation

Les scripts se lancent **depuis la racine du dépôt** et lisent la liste des postes dans `hosts.txt`.

```bash
cp hosts.txt.example hosts.txt      # puis adapter les adresses

# 1. Accès SSH (à faire une fois, dans cet ordre)
./acces-ssh/deploy-cles.sh
./acces-ssh/deploy-sudo.sh

# 2. Configuration du parc
./configuration/deploy_apt_proxy.sh
./alimentation/deploy-no-sleep.sh
./alimentation/deploy-cron.sh

# 3. Supervision (le token n'est jamais écrit dans le script)
export ZABBIX_API_TOKEN="votre_token"
./supervision/deploy-zabbix.sh

# 4. Wake-on-LAN : postes allumés d'abord, puis...
./alimentation/preparer-wol.sh
./alimentation/eteindre-postes.sh
./alimentation/rallumer-postes.sh
```

Variables d'environnement utiles : `SSH_USER` (compte d'administration, défaut `debian`) et `HOSTS_FILE` (autre liste de postes).

### Partie Active Directory

Ces scripts ne se lancent pas à la main : ils sont appelés par **PAM** (`pam_exec`) à l'ouverture de session, avec la variable `PAM_USER`. Principe :

1. `monter-classe.sh` monte le lecteur personnel, le lecteur d'échange et le lecteur de classe correspondant au **groupe AD** de l'utilisateur.
2. `configurer-sudo.sh` crée `/etc/sudoers.d/<utilisateur>` : sudo complet pour les professeurs, sudo limité (services, paquets, réseau, logs) pour les élèves.
3. `force-changer-mdp-pam.sh` lit l'attribut AD `info` de l'utilisateur. S'il ne vaut pas `mdp_changed`, il installe un lanceur KDE qui exécute `changer-mdp.py` au démarrage de la session.
4. `changer-mdp.py` demande le nouveau mot de passe (zenity), le change avec `smbpasswd`, pose le flag `info=mdp_changed` dans l'AD, puis redémarre le poste.

Seuls les comptes du domaine (UID ≥ 500000, plage SSSD) sont concernés ; les comptes locaux sont ignorés.

## Sécurité

- **Aucun secret dans le dépôt** : le token Zabbix se passe par variable d'environnement, le mot de passe du compte de service est lu dans `/etc/samba/credentials-ldap` (droits `600`, root uniquement).
- `hosts.txt` et `macs.txt` sont dans le `.gitignore` : ils décrivent votre infrastructure réelle.
- `eteindre-postes.sh` demande une confirmation avant d'éteindre tout le parc.

## Limites connues et pistes d'amélioration

Projet réalisé en environnement de laboratoire ; voici ce que je corrigerais pour de la production :

- Le sudo des élèves autorise `apt install`, `dpkg -i` ou `systemctl` : ces commandes permettent de devenir root. Acceptable en labo isolé, à restreindre sinon.
- Le mot de passe du compte de service est passé en argument (`ldapsearch -w`), donc visible dans la liste des processus. Préférer un fichier avec `-y`.
- `StrictHostKeyChecking=no` dans `deploy_apt_proxy.sh` simplifie le déploiement mais désactive la vérification des empreintes SSH.
- Les scripts de déploiement traitent les postes séquentiellement ; la parallélisation (ou Ansible) serait plus adaptée à un grand parc.
- `deploy-zabbix.sh` ajoute une ligne à `/etc/hosts` à chaque exécution (doublons possibles).

## Technologies

Bash · Python 3 · SSH · Active Directory · SSSD · Samba/CIFS · PAM · Zabbix (API JSON-RPC) · Wake-on-LAN · KDE Plasma
