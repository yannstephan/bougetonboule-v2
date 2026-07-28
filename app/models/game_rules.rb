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

  # Échec critique (retour de la v1) : 1 attaque sur 10 rate — 0 dégât et le monstre
  # mord 15 % du solde de l'attaquant (min 1, max 10 🍑 = au pire une sortie pleine).
  # Calibrage : solde typique d'un actif ~8 🍑 → perte 1, soit ~+10 % sur le coût moyen
  # d'une attaque (1,1 🍑 pour 10 PV) — l'attaque reste plus rentable que le soin (2 🍑).
  # Le ratio sur le solde taxe les thésauriseurs (pas de plafond de porte-monnaie en v2).
  # Volontairement NON multiplié par la jauge de meute : pénalité prévisible.
  CRIT_FAIL_CHANCE = 0.10
  CRIT_FAIL_RATIO  = 0.15
  CRIT_FAIL_MIN    = 1
  CRIT_FAIL_MAX    = 10

  # Pêches
  MAX_BALLS_PER_RUN = 10 # doublé les jours spéciaux (le multiplicateur s'applique après le plafond)
  # Plafond de porte-monnaie (retour v1) : une course ne verse que jusqu'à 100 🍑 en poche,
  # l'excédent est perdu (notifié). Le score de la course reste entier — la ligue le compte.
  # Avec l'échec critique (15 % du solde), c'est la double peine des thésauriseurs.
  WALLET_CAP = 100

  # Jauge de meute : +10 % permanents (attaques ET soins) par semaine où au moins
  # 5 coéquipiers ont chacun couru 10 km. Additif, plafonné à ×2 — jamais multiplicatif :
  # c'est le multiplicateur cumulable des Vitamines v1 qui avait fait mourir Fraizilla
  # à mi-saison.
  PACK_RUNNERS_NEEDED = 5
  PACK_WEEKLY_KM      = 10
  PACK_STEP           = 0.10
  PACK_MAX_LEVEL      = 10

  # Streak hebdo (💎, jugée le lundi par WeeklyStreakJob) : au moins une course scorée
  # dans la semaine → la série grandit et paie selon l'échelle (semaine 1 = 10 💎, puis
  # 20/30/40/50, plateau à 50). Tous les 5 paliers : cosmétique tiré au sort (fallback
  # 100 💎 si tout est possédé) + 1 joker (réserve max 2). Semaine ratée : un joker se
  # consomme et gèle la série (rien gagné, rien perdu) — sans joker, retour à zéro.
  # Les jokers ne s'achètent jamais (règle d'or). ~1 100 💎 max sur une saison parfaite
  # de 24 semaines — les prix boutique (100/250/500/1000 par rareté) sont calés dessus.
  STREAK_LADDER          = [10, 20, 30, 40, 50].freeze # 💎 par semaine, plateau ensuite
  STREAK_MILESTONE_EVERY = 5   # toutes les 5 semaines : cadeau + joker
  STREAK_GIFT_FALLBACK   = 100 # 💎 si le joueur possède déjà tous les cosmétiques
  STREAK_JOKER_MAX       = 2

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
