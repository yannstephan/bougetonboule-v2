# Le cookie de session doit SURVIVRE à la fermeture de l'app. Sans `expire_after`, Rails pose
# un cookie « de session » au sens du navigateur, sans date d'expiration : il disparaît dès
# que le navigateur ferme — et une PWA installée sur un téléphone est fermée en permanence.
# Chaque réouverture renvoyait donc sur l'écran de connexion, et comme on n'arrivait jamais
# jusqu'à l'écran Notifications, les push n'étaient jamais activés sur l'appareil.
#
# Un an glissant : le cookie est réécrit à chaque requête tant qu'on est connecté, donc un
# joueur qui ouvre l'app de temps en temps ne se reconnecte jamais. ⚠️ La clé reste celle
# que Rails dérivait du nom de l'app : la changer déconnecterait tout le monde.
Rails.application.config.session_store :cookie_store,
                                       key: "_bougetonboule_v2_session",
                                       expire_after: 1.year
