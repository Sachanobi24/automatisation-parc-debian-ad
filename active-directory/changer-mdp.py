#!/usr/bin/env python3
# ============================================================
# changer-mdp.py
# Changement de mot de passe AD au 1er login
# Utilise zenity (GUI GTK) + smbpasswd
# Flag stocké dans l'attribut 'info' de l'objet AD
# ============================================================

import subprocess
import os
import sys
import datetime

AD_SERVER  = "10.0.100.20"
BASE_DN    = "DC=exemple,DC=local"
BIND_DN    = "svc-montage@EXEMPLE.LOCAL"
CREDS_FILE = "/etc/samba/credentials-ldap"
LOG_FILE   = "/var/log/changer-mdp.log"

# ────────────────────────────────────────────────────────────
# Helpers
# ────────────────────────────────────────────────────────────

def log(msg):
    try:
        with open(LOG_FILE, "a") as f:
            f.write(f"[{datetime.datetime.now()}] "
                    f"{os.environ.get('USER','?')} — {msg}\n")
    except Exception:
        pass

def lire_credentials():
    """Parse /etc/samba/credentials-ldap → dict"""
    creds = {}
    try:
        with open(CREDS_FILE) as f:
            for line in f:
                line = line.strip()
                if "=" in line:
                    k, v = line.split("=", 1)
                    creds[k.strip()] = v.strip()
    except Exception as e:
        log(f"Erreur lecture credentials : {e}")
    return creds

def zenity(*args):
    env = os.environ.copy()
    env["DISPLAY"] = os.environ.get("DISPLAY", ":0")
    try:
        r = subprocess.run(
            ["zenity"] + list(args),
            capture_output=True, text=True, env=env, timeout=120
        )
        return r.returncode, r.stdout.strip()
    except FileNotFoundError:
        log("zenity introuvable — sudo apt install zenity")
        sys.exit(1)
    except subprocess.TimeoutExpired:
        return 1, ""

def demander_mdp(titre, texte):
    code, val = zenity("--password", "--title", titre, "--text", texte)
    return code == 0, val

def afficher_info(titre, texte):
    zenity("--info", "--title", titre, "--text", texte, "--width", "400")

def afficher_erreur(titre, texte):
    zenity("--error", "--title", titre, "--text", texte, "--width", "400")

# ────────────────────────────────────────────────────────────
# AD — récupération du DN réel de l'utilisateur
# ────────────────────────────────────────────────────────────

def get_user_dn(user, svc_password):
    """Retourne le DN complet de l'utilisateur dans l'AD"""
    try:
        proc = subprocess.run(
            ["ldapsearch",
             "-H", f"ldap://{AD_SERVER}",
             "-D", BIND_DN,
             "-w", svc_password,
             "-b", BASE_DN,
             f"(sAMAccountName={user})",
             "dn"],
            capture_output=True, text=True, timeout=10
        )
        for line in proc.stdout.splitlines():
            if line.lower().startswith("dn:"):
                dn = line.split(":", 1)[1].strip()
                log(f"DN trouvé : {dn}")
                return dn
    except Exception as e:
        log(f"Erreur get_user_dn : {e}")
    return None

# ────────────────────────────────────────────────────────────
# AD — vérification et pose du flag
# ────────────────────────────────────────────────────────────

def flag_ad_pose(user, svc_password):
    """Retourne True si l'attribut info vaut 'mdp_changed'"""
    try:
        proc = subprocess.run(
            ["ldapsearch",
             "-H", f"ldap://{AD_SERVER}",
             "-D", BIND_DN,
             "-w", svc_password,
             "-b", BASE_DN,
             f"(sAMAccountName={user})",
             "info"],
            capture_output=True, text=True, timeout=10
        )
        for line in proc.stdout.splitlines():
            if line.startswith("info:"):
                valeur = line.split(":", 1)[1].strip()
                log(f"Attribut info AD = '{valeur}'")
                return valeur == "mdp_changed"
    except Exception as e:
        log(f"Erreur ldapsearch flag : {e}")
    return False

def poser_flag_ad(user, svc_password):
    """Écrit info=mdp_changed sur l'objet utilisateur AD"""
    # Récupérer le DN réel
    dn = get_user_dn(user, svc_password)
    if not dn:
        log("ERREUR : DN introuvable, flag non posé")
        return False

    ldif = (
        f"dn: {dn}\n"
        f"changetype: modify\n"
        f"replace: info\n"
        f"info: mdp_changed\n"
    )
    try:
        proc = subprocess.run(
            ["ldapmodify",
             "-H", f"ldap://{AD_SERVER}",
             "-D", BIND_DN,
             "-w", svc_password],
            input=ldif,
            capture_output=True, text=True, timeout=10
        )
        log(f"ldapmodify code={proc.returncode} stdout={proc.stdout.strip()} stderr={proc.stderr.strip()}")
        return proc.returncode == 0
    except Exception as e:
        log(f"Erreur ldapmodify : {e}")
        return False

# ────────────────────────────────────────────────────────────
# Suppression du lanceur KDE
# ────────────────────────────────────────────────────────────

def supprimer_lanceur(user):
    lanceur = f"/home/{user}/.config/plasma-workspace/env/force-changer-mdp.sh"
    try:
        if os.path.exists(lanceur):
            os.remove(lanceur)
            log("Lanceur KDE supprimé")
        else:
            log("Lanceur KDE déjà absent")
    except Exception as e:
        log(f"Erreur suppression lanceur : {e}")

# ────────────────────────────────────────────────────────────
# Changement de mot de passe
# ────────────────────────────────────────────────────────────

def changer_motdepasse(user, old_pass, new_pass):
    try:
        proc = subprocess.run(
            ["smbpasswd", "-r", AD_SERVER, "-U", user],
            input=f"{old_pass}\n{new_pass}\n{new_pass}\n",
            capture_output=True, text=True, timeout=15
        )
        sortie = proc.stdout + proc.stderr
        log(f"smbpasswd code={proc.returncode} sortie={sortie.strip()}")

        if "Password changed" in sortie or proc.returncode == 0:
            return True, ""

        lines = [l for l in sortie.splitlines()
                 if l.strip() and "spawn" not in l.lower()]
        return False, "\n".join(lines[:3]) if lines else "Erreur inconnue"

    except subprocess.TimeoutExpired:
        return False, "Délai dépassé — serveur AD inaccessible"
    except FileNotFoundError:
        return False, "smbpasswd introuvable — vérifier samba-common-bin"
    except Exception as e:
        return False, str(e)

def invalider_cache(user):
    try:
        subprocess.run(["sudo", "sss_cache", "-u", user],
                       capture_output=True, timeout=5)
        log("Cache SSSD invalidé")
    except Exception:
        log("Impossible d'invalider le cache SSSD")

def rebooter():
    try:
        subprocess.run(["sudo", "systemctl", "reboot"],
                       capture_output=True, timeout=10)
    except Exception:
        pass

# ────────────────────────────────────────────────────────────
# Main
# ────────────────────────────────────────────────────────────

def main():
    user = os.environ.get("USER", "")

    if os.getuid() < 500000:
        log("Utilisateur système — ignoré")
        sys.exit(0)

    creds = lire_credentials()
    svc_password = creds.get("password", "")

    if not svc_password:
        log("ERREUR : mot de passe svc-montage vide — vérifier /etc/samba/credentials-ldap")
        sys.exit(1)

    # Vérifier le flag dans l'AD
    if flag_ad_pose(user, svc_password):
        log("Flag AD présent — skip")
        supprimer_lanceur(user)
        sys.exit(0)

    log("Lancement changement mot de passe")

    afficher_info(
        "Première connexion — Bienvenue",
        f"Bonjour {user} !\n\n"
        "Pour des raisons de sécurité, vous devez\n"
        "changer votre mot de passe avant de commencer.\n\n"
        "Cliquez sur OK pour continuer."
    )

    while True:

        ok, old_pass = demander_mdp(
            "Étape 1/3 — Mot de passe actuel",
            "Saisissez le mot de passe fourni par votre professeur :"
        )
        if not ok:
            continue

        ok, new_pass = demander_mdp(
            "Étape 2/3 — Nouveau mot de passe",
            "Saisissez le mot de passe de votre choix\n(6 caractères minimum) :"
        )
        if not ok:
            continue

        ok, confirm_pass = demander_mdp(
            "Étape 3/3 — Confirmation",
            "Confirmez votre nouveau mot de passe :"
        )
        if not ok:
            continue

        if len(new_pass) < 6:
            afficher_erreur("Erreur",
                "Le mot de passe doit contenir\nau moins 6 caractères.")
            continue

        if new_pass != confirm_pass:
            afficher_erreur("Erreur",
                "Les mots de passe ne correspondent pas.\nRecommencez.")
            continue

        if new_pass == old_pass:
            afficher_erreur("Erreur",
                "Le nouveau mot de passe doit être\ndifférent de l'actuel.")
            continue

        ok, erreur = changer_motdepasse(user, old_pass, new_pass)

        if ok:
            log("Changement réussi")

            if poser_flag_ad(user, svc_password):
                log("Flag AD posé avec succès")
            else:
                log("ATTENTION : flag AD non posé")

            supprimer_lanceur(user)
            invalider_cache(user)

            afficher_info(
                "Succès !",
                "Mot de passe changé avec succès !\n\n"
                "Bienvenue dans le domaine exemple.local !\n"
                "Votre ordinateur va redémarrer.\n"
                "Reconnectez-vous avec votre nouveau mot de passe."
            )

            rebooter()
            break

        else:
            log(f"Échec : {erreur}")
            afficher_erreur(
                "Échec du changement",
                f"Le changement a échoué :\n{erreur}\n\n"
                "Vérifiez votre mot de passe actuel et réessayez."
            )

if __name__ == "__main__":
    main()

