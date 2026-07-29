# Jeu de données de démonstration — valide le schéma et sert d'exemple.
puts "Nettoyage…"
Game.update_all(winner_team_id: nil) # FK games → teams : à détacher avant de supprimer les équipes
[Reward, Chest, ConversationRead, Message, Conversation, Notification, PushSubscription,
 Action, MembershipItem, Training, TeamEffect, Membership, Monster, Team,
 SpecialDay, Game, Event, UserCosmetic, Cosmetic, Item, User].each(&:delete_all)

puts "Cosmétiques…"
# Prix calés sur la streak hebdo (~1 100 💎 max sur une saison parfaite, voir GameRules) :
# common ~100 · rare ~250 · epic ~500 · legendary 1000.
Cosmetic.create!([
  # Chapeaux
  { name: "Haut-de-forme doré", slot: "hat",  rarity: "legendary", price_diamonds: 1000, source: "shop",  emoji: "🎩" },
  { name: "Casquette",          slot: "hat",  rarity: "rare",      price_diamonds: 250,  source: "shop",  emoji: "🧢" },
  { name: "Bandeau",            slot: "hat",  rarity: "common",    price_diamonds: 90,   source: "shop",  emoji: "🎀" },
  { name: "Capeline d'été",     slot: "hat",  rarity: "common",    price_diamonds: 100,  source: "shop",  emoji: "👒" },
  { name: "Chapeau de cowboy",  slot: "hat",  rarity: "rare",      price_diamonds: 260,  source: "shop",  emoji: "🤠" },
  { name: "Toque de diplômé",   slot: "hat",  rarity: "epic",      price_diamonds: 500,  source: "shop",  emoji: "🎓" },
  # Yeux
  { name: "Lunettes de star",   slot: "eyes", rarity: "epic",      price_diamonds: 500,  source: "shop",  emoji: "🕶️" },
  { name: "Lunettes rondes",    slot: "eyes", rarity: "common",    price_diamonds: 100,  source: "shop",  emoji: "👓" },
  { name: "Lunettes de piscine", slot: "eyes", rarity: "common",   price_diamonds: 90,   source: "shop",  emoji: "🥽" },
  { name: "Masque de théâtre",  slot: "eyes", rarity: "epic",      price_diamonds: 520,  source: "shop",  emoji: "🎭" },
  # Tenues
  { name: "Maillot de course",  slot: "outfit", rarity: "common",  price_diamonds: 100,  source: "shop",  emoji: "🎽" },
  { name: "Gilet fluo",         slot: "outfit", rarity: "common",  price_diamonds: 90,   source: "shop",  emoji: "🦺" },
  { name: "Kimono de soie",     slot: "outfit", rarity: "rare",    price_diamonds: 250,  source: "shop",  emoji: "👘" },
  { name: "Kimono de combat",   slot: "outfit", rarity: "epic",    price_diamonds: 500,  source: "shop",  emoji: "🥋" },
  # Bras
  { name: "Gants de boxe",      slot: "arms", rarity: "rare",      price_diamonds: 260,  source: "shop",  emoji: "🥊" },
  { name: "Gants d'hiver",      slot: "arms", rarity: "common",    price_diamonds: 90,   source: "shop",  emoji: "🧤" },
  { name: "Montre GPS",         slot: "arms", rarity: "rare",      price_diamonds: 250,  source: "shop",  emoji: "⌚" },
  # Jambes
  { name: "Baskets de course",  slot: "legs", rarity: "rare",      price_diamonds: 240,  source: "shop",  emoji: "👟" },
  { name: "Short de course",    slot: "legs", rarity: "common",    price_diamonds: 100,  source: "shop",  emoji: "🩳" },
  { name: "Chaussures de rando", slot: "legs", rarity: "rare",     price_diamonds: 240,  source: "shop",  emoji: "🥾" },
  { name: "Rollers dorés",      slot: "legs", rarity: "epic",      price_diamonds: 500,  source: "shop",  emoji: "🛼" },
  # Auras
  { name: "Aura pêche",         slot: "aura", rarity: "common",    price_diamonds: 120,  source: "shop",  emoji: "✨" },
  { name: "Aura de feu",        slot: "aura", rarity: "epic",      price_diamonds: 550,  source: "shop",  emoji: "🔥" },
  { name: "Pétales de cerisier", slot: "aura", rarity: "common",   price_diamonds: 110,  source: "shop",  emoji: "🌸" },
  { name: "Aura de givre",      slot: "aura", rarity: "rare",      price_diamonds: 250,  source: "shop",  emoji: "❄️" },
  { name: "Aura électrique",    slot: "aura", rarity: "epic",      price_diamonds: 550,  source: "shop",  emoji: "⚡" },
  { name: "Arc-en-ciel",        slot: "aura", rarity: "legendary", price_diamonds: 1000, source: "shop",  emoji: "🌈" },
  # Exclusives — jamais en vente (price nil) : tirages (streak, ligue), coffres, jours spéciaux
  { name: "Couronne de Noël",   slot: "hat",  rarity: "legendary", price_diamonds: nil,  source: "event", emoji: "👑" },
  { name: "Bonnet du Réveillon", slot: "hat", rarity: "epic",      price_diamonds: nil,  source: "event", emoji: "🎅" },
  { name: "Citrouille maudite", slot: "hat",  rarity: "epic",      price_diamonds: nil,  source: "event", emoji: "🎃" },
  { name: "Médaille d'Odyssea", slot: "outfit", rarity: "legendary", price_diamonds: nil, source: "rank", emoji: "🏅" },
  { name: "Esprit du loup",     slot: "aura", rarity: "legendary", price_diamonds: nil,  source: "drop",  emoji: "🐺" },
])

puts "Objets (power-ups)…"
# Prix calibrés sur les données de la saison v1 (~10 🍑/semaine pour un actif médian).
# Le booster n'est plus un objet : c'est la jauge de meute (PackLevelJob), gagnée en courant.
Item.create!([
  { name: "Jambe de bois", price: 4, description: "Déjoue le prochain piège sur ta course",             effect_type: "wooden_leg" },
  { name: "Vent de dos",   price: 4, description: "×1,5 sur les boules de l'équipe pendant 12h",        effect_type: "back_wind" },
  { name: "Vent de face",  price: 4, description: "−25 % sur les boules adverses pendant 12h",          effect_type: "face_wind" },
  { name: "Fumigène",      price: 4, description: "Masque les PV d'un monstre aux yeux de l'équipe adverse (24h)", effect_type: "smoke" },
  { name: "Piège à loup",  price: 5, description: "Annule les boules de la prochaine course d'un adversaire", effect_type: "trap" },
  { name: "Bouclier",      price: 6, description: "Monstre intouchable pendant 6h",                     effect_type: "shield" },
])

puts "Event + partie…"
event = Event.create!(name: "Odyssea Nantes", race_date: Time.zone.local(2027, 3, 21, 9, 0), location: "Nantes")
game  = Game.create!(event:, name: "Partie Odyssea 2027", status: "active",
                     starts_at: 7.weeks.ago, ends_at: 8.weeks.from_now)

# Le duel d'Odyssea 2027 : Fruits exotiques (King-Coco) vs Fruits rouges (Framboitrix).
exo    = Team.create!(game:, name: "Fruits exotiques", color: "#f6b93b", fruit_family: "exotiques")
rouges = Team.create!(game:, name: "Fruits rouges",    color: "#f0325b", fruit_family: "rouges")
exo.update!(opponent: rouges); rouges.update!(opponent: exo)

# PV calibrés pour une saison de ~24 semaines (voir GameRules::MONSTER_MAX_HP).
Monster.create!(team: exo,    name: "King-Coco",  hp: 4_600, max_hp: GameRules::MONSTER_MAX_HP, state: "hurt")
Monster.create!(team: rouges, name: "Framboitrix",  hp: 2_510, max_hp: GameRules::MONSTER_MAX_HP, state: "hurt")

# La jauge de meute (semaines où ≥5 coéquipiers ont couru ≥10 km) : quelques paliers déjà gagnés.
exo.update!(pack_level: 3)
rouges.update!(pack_level: 2)

Conversation.create!(game:, kind: "general")
Conversation.create!(game:, kind: "team", team: exo)
Conversation.create!(game:, kind: "team", team: rouges)

# Journées ×2 de la saison (boules ET plafond doublés) — 2 fixées, les suivantes en cours de route.
SpecialDay.create!(game:, name: "Halloween",         date: Date.new(2026, 10, 31), multiplier: 2)
SpecialDay.create!(game:, name: "Réveillon de Noël", date: Date.new(2026, 12, 24), multiplier: 2)

puts "Joueurs…"
weeks_of_history = 6 # semaines de courses passées, en plus de la semaine en cours

week_start   = Date.current.beginning_of_week
days_elapsed = (Date.current - week_start).to_i

# Deux équipes complètes de 5. `runs` = sorties/semaine, `km` = distance typique d'une sortie :
# de quoi produire des profils de coureurs différents (assidus, occasionnels, gros volumes).
# `fruit` : l'avatar-fruit, dans la famille de l'équipe (voir FruitCatalog).
roster = [
  { name: "Yann",  team: :exo,    runs: 4, km: 6..11, fruit: "ananas",    role: "admin" },
  { name: "Léa",   team: :exo,    runs: 3, km: 5..9,  fruit: "mangue" },
  { name: "Nico",  team: :exo,    runs: 2, km: 4..7,  fruit: "kiwi" },
  { name: "Inès",  team: :exo,    runs: 5, km: 7..14, fruit: "dragon" },
  { name: "Hugo",  team: :exo,    runs: 1, km: 3..6,  fruit: "banane" },
  { name: "Max",   team: :rouges, runs: 3, km: 6..10, fruit: "cerise" },
  { name: "Chloé", team: :rouges, runs: 4, km: 8..13, fruit: "fraise" },
  { name: "Sam",   team: :rouges, runs: 2, km: 4..8,  fruit: "cassis" },
  { name: "Anaïs", team: :rouges, runs: 3, km: 5..12, fruit: "myrtille" },
  { name: "Théo",  team: :rouges, runs: 1, km: 9..15, fruit: "grenade" }
]

RUN_TITLES = ["Footing du matin", "Sortie longue", "Fractionné piste", "Récup tranquille",
              "Tempo au bord de l'Erdre", "Trail urbain", "Sortie club", "Petit tour digestif"].freeze
RUN_NOTES  = [nil, nil, "Jambes lourdes mais content d'être sorti.", "Nickel, beau soleil sur la Loire ☀️",
              "Objectif allure tenu 💪", "Un peu de vent de face au retour.", nil].freeze

# Parcours GPS synthétique : une boucle bruitée autour de Nantes, dimensionnée par la distance.
def seed_route(distance_meters)
  center = [47.2184 + rand(-0.02..0.02), -1.5536 + rand(-0.02..0.02)]
  radius = (distance_meters / 6.283 / 111_000.0) * rand(0.4..0.7)
  klng = Math.cos(center[0] * Math::PI / 180)
  (0..32).map do |i|
    angle = (2 * Math::PI * i / 32) + rand(-0.15..0.15)
    r = radius * (0.7 + rand * 0.6)
    [(center[0] + r * Math.sin(angle)).round(5), (center[1] + r * Math.cos(angle) / klng).round(5)]
  end
end

# Une sortie passée, scorée par TrainingScorer (plafond puis jours spéciaux/vents) puis créditée
# en 🍑 — enrichie des détails qu'on récupérerait de Strava (titre, temps, dénivelé, tracé).
def seed_training!(membership, day, distance_meters)
  km = distance_meters / 1000.0
  moving = (km * rand(290..360)).round
  training = Training.new(
    membership:, date: day.to_time + rand(7..19).hours, distance_meters:, status: "verified",
    title: RUN_TITLES.sample, description: RUN_NOTES.sample,
    moving_time: moving, elapsed_time: moving + rand(0..280),
    elevation_gain: rand(4..180), route_points: seed_route(distance_meters)
  )
  TrainingScorer.call(training)
  training.save!
  training.credit_balls! # verse les 🍑 à la participation, comme à l'import Strava réel
end

# Mot de passe commun aux joueurs de démo : on peut se connecter en tant que n'importe lequel
# (ex. yann@btb.test) pour voir le jeu et le feed de notifications sans repartir de zéro.
DEMO_PASSWORD = "odyssea2027".freeze

roster.each do |p|
  user = User.create!(firstname: p[:name], diamonds: rand(150..900), password: DEMO_PASSWORD,
                      email: "#{p[:name].downcase.tr('éèàï', 'eeai')}@btb.test")
  team = p[:team] == :exo ? exo : rouges
  streak = [weeks_of_history, p[:runs] * 2].min
  # balls: 0 — le solde est ensuite crédité par les courses (credit_balls! dans seed_training!).
  m = Membership.create!(user:, game:, team:, fruit: p[:fruit], balls: 0,
                         role: p[:role] || "player", weekly_streak: streak,
                         best_streak: weeks_of_history, last_streak_week: week_start,
                         streak_jokers: streak >= GameRules::STREAK_MILESTONE_EVERY ? 1 : 0)

  # Historique : les semaines passées, en entier.
  weeks_of_history.downto(1) do |w|
    past_week = week_start - w.weeks
    # Une semaine sautée de temps en temps, sinon tout le monde a un historique parfait.
    next if w > 1 && rand < 0.15

    rand(p[:runs] - 1..p[:runs]).clamp(1, 7).times do |d|
      seed_training!(m, past_week + (d * 7 / p[:runs]), rand(p[:km]) * 1000 + rand(0..999))
    end
  end

  # Semaine EN COURS : réparties sur les jours déjà écoulés, pour que la ligue ne soit pas vide.
  [p[:runs], days_elapsed + 1].min.times do |d|
    seed_training!(m, week_start + (d % (days_elapsed + 1)), rand(p[:km]) * 1000 + rand(0..999))
  end
end

first = Membership.first
Chest.create!(membership: first, rarity: "epic", reward_diamonds: 35,
              cosmetic: Cosmetic.find_by(name: "Haut-de-forme doré"))
Notification.create!(user: first.user, game:, category: "chest", importance: "important",
                     title: "Tu as trouvé un coffre épique", body: "Ouvre-le pour tes récompenses !")
if first.weekly_streak.positive?
  Notification.create!(user: first.user, game:, category: "streak", importance: "important",
                       title: "🔥 #{first.weekly_streak} semaines de course d'affilée !",
                       body: "+#{GameRules::STREAK_LADDER[[first.weekly_streak, GameRules::STREAK_LADDER.size].min - 1]} 💎")
end

puts "Cosmétiques possédés…"
# De quoi voir l'écran avatar rempli sans avoir à gagner un mois de classement.
[["Yann", "Casquette", true], ["Yann", "Aura de feu", true], ["Yann", "Baskets de course", true],
 ["Inès", "Lunettes de star", true], ["Inès", "Gants de boxe", true],
 ["Chloé", "Haut-de-forme doré", false]].each do |name, cosmetic, on|
  user = User.find_by(firstname: name)
  UserCosmetic.create!(user:, cosmetic: Cosmetic.find_by(name: cosmetic),
                       equipped: on, acquired_at: 2.weeks.ago, source_game: game)
end

puts "Messages…"
general = game.general_conversation
[["Yann", "Allez les exotiques, on a un mois à gagner 🌴"],
 ["Chloé", "Vous allez pleurer, Framboitrix a faim 🍒"],
 ["Inès", "10 km ce matin, King-Coco vous salue 🥥"],
 ["Théo", "Qui court demain matin ?"]].each_with_index do |(name, body), i|
  m = Membership.joins(:user).find_by(users: { firstname: name })
  Message.create!(conversation: general, membership: m, body:, created_at: (4 - i).hours.ago)
end

game.conversations.team_chats.find_each do |conv|
  conv.team.memberships.limit(2).each_with_index do |m, i|
    Message.create!(conversation: conv, membership: m, created_at: (2 - i).hours.ago,
                    body: i.zero? ? "On concentre les attaques ce soir ?" : "Ok, je garde mes boules 🍑")
  end
end

puts "Activité simulée (pour voir le feed de notifications)…"
# On rejoue de vrais événements de jeu via les services (PerformAction), pour que le feed de
# notifications ressemble exactement à ce qu'on verrait en jouant : effets d'équipe, piège,
# courses, messages. Se connecter en tant que Yann (yann@btb.test) montre le résultat complet.
by_name = ->(n) { Membership.joins(:user).find_by(users: { firstname: n }) }
yann, ines, lea, nico = by_name["Yann"], by_name["Inès"], by_name["Léa"], by_name["Nico"]
max_m, chloe = by_name["Max"], by_name["Chloé"]

before_id = Notification.maximum(:id) || 0

# Un objet posé dans l'inventaire puis utilisé, exactement comme un achat en boutique + « Utiliser ».
use_effect = lambda do |membership, effect_type, target: nil, target_team: nil|
  item = Item.find_by(effect_type:)
  MembershipItem.create!(membership:, item:, used: false)
  PerformAction.call(membership, action_type: "use_item", item_id: item.id,
                     target_id: target&.id, target_team:)
end

# Importe une course « maintenant » par tout le pipeline réel (scoring + résolution piège/jambe
# de bois + crédit des 🍑 + notifications), exactement comme StravaActivityImportJob.
seed_import = lambda do |membership, distance_meters|
  km = distance_meters / 1000.0
  moving = (km * rand(290..360)).round
  t = membership.trainings.build(date: Time.current, distance_meters:, status: "verified",
                                 title: RUN_TITLES.sample, moving_time: moving,
                                 elapsed_time: moving + rand(0..200), elevation_gain: rand(4..120),
                                 route_points: seed_route(distance_meters))
  TrainingScorer.call(t)
  ResolveRunEffects.call(t) # piège à loup / jambe de bois + notifs importantes aux deux camps
  t.save!
  t.credit_balls!           # rien n'est versé si la course est piégée (score 0)
  gain = t.status == "trapped" ? "piégée 🐺 · 0 🍑" : "+#{t.score.to_i} 🍑"
  link = "/courses/#{t.id}"
  others = game.memberships.includes(:user).where.not(id: membership.id).map(&:user)
  Notification.broadcast(others, game:, category: "training_verified", title: "🏃 Nouvelle course", link:,
                         body: "#{membership.display_name} a couru #{t.distance_km.round(1)} km · #{gain}")
  Notification.create!(user: membership.user, game:, category: "training_verified", link:,
                       title: "Course importée", body: "#{t.distance_km.round(1)} km · +#{t.score.to_i} boules")
end

use_effect[max_m, "back_wind"]          # 🌬️ Max (rouges) : vent de dos → annonce secondaire à tous
use_effect[ines, "shield"]              # 🛡️ Inès (exo) : bouclier sur King-Coco → secondaire à tous
use_effect[lea, "face_wind"]            # 🌪️ Léa (exo) : vent de face sur les rouges → notif importante aux victimes
# 🌫️ Hugo (exo) enfume les rouges et masque LEUR monstre (Framboitrix, target_team "foe") :
# les rouges voient les PV de Framboitrix en « ??? » (login max@btb.test) mais toujours ceux de
# King-Coco ; le chip 🌫️ « Framboitrix masqué » s'affiche sur leur board. Yann (exo) voit tout.
use_effect[by_name["Hugo"], "smoke", target_team: "foe"]

# 🐺 Pièges à loup + 🦿 jambe de bois, résolus juste après à l'import d'une course (ResolveRunEffects).
use_effect[yann, "wooden_leg"]           # Yann s'arme discrètement (rien n'est annoncé)
use_effect[chloe, "trap", target: yann]  # Chloé piège Yann → sera déjoué par la jambe de bois
use_effect[chloe, "trap", target: nico]  # Chloé piège Nico (sans jambe) → course annulée (0 🍑)

# ⚔️ Deux attaques d'Inès sur Framboitrix : la 1re le fait passer sous 25 % → Second souffle des rouges
# (notif importante : soins à 1 🍑 pendant 7 jours). Puis un soin de Léa sur King-Coco.
PerformAction.call(ines, action_type: "attack")
PerformAction.call(ines, action_type: "attack")
PerformAction.call(lea,  action_type: "heal")

# 🏃 Courses importées par le pipeline complet — dont les deux issues d'un piège.
seed_import[yann, 8_400]  # 🦿 piège déjoué → « Piège déjoué ! » (importante) à Yann, 🍑 sauvées
seed_import[nico, 6_200]  # 🐺 piège refermé → « Course piégée ! » (importante) à Nico, 0 🍑
seed_import[ines, 10_400] # course normale (exo, pas de vent)
seed_import[max_m, 7_200] # course normale (rouges : vent de dos ×1,5 × vent de face ×0,75)

# Message d'équipe = important (poussé) : n'arrive qu'aux coéquipiers de Léa (exo).
# Le chat général ne notifie pas (on le suit en ouvrant le chat).
Notification.broadcast(exo.memberships.includes(:user).where.not(id: lea.id).map(&:user),
                       game:, importance: "important", category: "message", title: "💬 Léa · équipe",
                       body: "On concentre les attaques ce soir sur Framboitrix ?")

# Étale les horodatages sur les dernières heures pour un feed lisible (sinon tout à la même minute).
fresh = Notification.where("id > ?", before_id).order(:id).to_a
fresh.each_with_index { |n, i| n.update_column(:created_at, ((fresh.size - i) * 23).minutes.ago) }

puts "OK — #{User.count} joueurs, #{Training.count} courses sur #{weeks_of_history + 1} semaines, " \
     "#{Team.count} équipes, #{Cosmetic.count} cosmétiques."
Team.all.each do |t|
  km = Training.where(membership: t.memberships).sum(:distance_meters) / 1000.0
  puts "   #{t.name} : #{t.memberships.count} joueurs, #{km.round} km cumulés, " \
       "#{t.total_balls} 🍑 en banque (créditées par les courses), meute +#{t.pack_percent} %"
end
puts "   Statuts de course : #{Training.group(:status).count} · #{Training.where.not(balls_credited_at: nil).count} créditées"
puts "👉 Connexion démo : yann@btb.test / #{DEMO_PASSWORD} " \
     "(Yann/exo voit tout — vents, bouclier, chip 🌫️ sur les rouges, second souffle de Framboitrix, " \
     "jauge de meute, 🍑 créditées, sa course dont le piège a été déjoué). " \
     "Se connecter en max@btb.test (rouges enfumés) pour voir les PV masqués en « ??? »."
