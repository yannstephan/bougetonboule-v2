# Toutes les constantes d'équilibrage du jeu, calibrées sur les données réelles de la
# saison v1 (dump Odyssea 2026 : ~165 🍑/semaine pour un groupe de 15 coureurs actifs).
# Saison cible : 1er octobre → 15 mars (~24 semaines).
module GameRules
  # Monstres
  MONSTER_MAX_HP = 10_000 # tuable dans les dernières semaines seulement

  # Combat — le soin coûte le double : l'attaque doit rester plus rentable
  # que la défense pour garantir que la partie se décide.
  ATTACK_COST = 1
  HEAL_COST   = 2
  BASE_POWER  = 10 # PV par action, × le multiplicateur de meute

  # Pêches
  MAX_BALLS_PER_RUN = 10 # doublé les jours spéciaux (le multiplicateur s'applique après le plafond)

  # Jauge de meute : +10 % permanents (attaques ET soins) par semaine où au moins
  # 5 coéquipiers ont chacun couru 10 km. Additif, plafonné à ×2 — jamais multiplicatif :
  # c'est le multiplicateur cumulable des Vitamines v1 qui avait fait mourir Fraizilla
  # à mi-saison.
  PACK_RUNNERS_NEEDED = 5
  PACK_WEEKLY_KM      = 10
  PACK_STEP           = 0.10
  PACK_MAX_LEVEL      = 10

  # Effets d'objets
  SHIELD_DURATION = 6.hours
  WIND_DURATION   = 12.hours
  BACK_WIND_MODIFIER = 1.5  # ×1,5 sur les 🍑 de l'équipe
  FACE_WIND_MODIFIER = 0.75 # −25 % sur les 🍑 de l'équipe adverse
  SMOKE_DURATION  = 24.hours

  # Second souffle : monstre sous 25 % → soins à 1 🍑 pendant 7 jours, 1×/équipe/partie.
  SECOND_WIND_THRESHOLD = 0.25
  SECOND_WIND_DURATION  = 7.days
  SECOND_WIND_HEAL_COST = 1

  # Monstre affamé : sans aucune course de l'équipe pendant 72h, il perd 50 PV/jour.
  # Plancher à 5 % : la famine ne tue jamais, le coup final reste aux joueurs.
  FAMINE_WARNING_AFTER = 48.hours # avertissement sur le Hub
  FAMINE_AFTER         = 72.hours
  FAMINE_HP_PER_DAY    = 50
  FAMINE_FLOOR_RATIO   = 0.05
end
