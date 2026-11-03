#!/bin/bash
# Notifie les sessions graphiques actives, puis programme l'extinction.

DELAI=5   # minutes avant extinction
MESSAGE="Le poste va s'eteindre dans ${DELAI} minutes. Pensez a enregistrer votre travail."

# Parcourt les sessions de connexion
loginctl list-sessions --no-legend | awk '{print $1}' | while read -r session; do
    etat=$(loginctl show-session "$session" -p State --value)
    type=$(loginctl show-session "$session" -p Type --value)

    # On ne garde que les sessions graphiques actives
    [ "$etat" = "active" ] || continue
    case "$type" in x11|wayland) ;; *) continue ;; esac

    uid=$(loginctl show-session "$session" -p User --value)
    user=$(loginctl show-session "$session" -p Name --value)

    # Envoi de la notif DANS la session de l'utilisateur
    sudo -u "$user" \
        env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${uid}/bus" DISPLAY=":0" \
        notify-send -u critical -i system-shutdown "Extinction programmee" "$MESSAGE"
done

# Programme l'extinction reelle
/sbin/shutdown -h +${DELAI} "Extinction automatique"
