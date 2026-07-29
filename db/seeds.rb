# Jeu de données de démonstration — valide le schéma et sert d'exemple.
puts "Nettoyage…"
Game.update_all(winner_team_id: nil) # FK games → teams : à détacher avant de supprimer les équipes
[Reward, Chest, ConversationRead, Message, Conversation, Notification, PushSubscription,
 Action, MembershipItem, Training, TeamEffect, Membership, Monster, Team,
 SpecialDay, Game, Event, UserCosmetic, Cosmetic, Item, User].each(&:delete_all)

puts "Cosmétiques…"
# L'avatar est une TÊTE de fruit : 7 emplacements, ni tenue ni jambes (voir Cosmetic::SLOTS).
# Prix calés sur la streak hebdo (~1 100 💎 max sur une saison parfaite, voir GameRules) :
# common ~100 · rare ~250 · epic ~500 · legendary 1000.
#
# `emoji` par défaut ; `art` quand l'emoji ne peut pas faire le travail — les chaussures
# (👟 🥾 🛼 sont des godasses uniques vues de profil, on veut une PAIRE de face) et les
# pièces dont l'emoji est un visage entier (🤠 🧐 🎅 auraient collé une tête sur la tête).
# Chaque clé `art` doit exister dans components/cosmeticArt.jsx.
Cosmetic.create!([
  # Chapeaux — posés sur le sommet réel du fruit (voir fruits.js → box)
  { name: "Bandeau éponge",     slot: "hat",  rarity: "common",    price_diamonds: 90,   source: "shop",  emoji: "🎀" },
  { name: "Casquette",          slot: "hat",  rarity: "common",    price_diamonds: 100,  source: "shop",  emoji: "🧢" },
  { name: "Capeline d'été",     slot: "hat",  rarity: "common",    price_diamonds: 100,  source: "shop",  emoji: "👒" },
  { name: "Bob du dimanche",    slot: "hat",  rarity: "rare",      price_diamonds: 240,  source: "shop",  art: "bucket_hat" },
  { name: "Chapeau de cowboy",  slot: "hat",  rarity: "rare",      price_diamonds: 250,  source: "shop",  art: "cowboy_hat" },
  { name: "Toque de diplômé",   slot: "hat",  rarity: "epic",      price_diamonds: 500,  source: "shop",  emoji: "🎓" },
  { name: "Casque de chantier", slot: "hat",  rarity: "epic",      price_diamonds: 500,  source: "shop",  emoji: "⛑️" },
  { name: "Haut-de-forme doré", slot: "hat",  rarity: "legendary", price_diamonds: 1000, source: "shop",  art: "gold_hat" },
  # Lunettes — sur la ligne des yeux, commune à tous les fruits
  { name: "Lunettes rondes",    slot: "eyes", rarity: "common",    price_diamonds: 90,   source: "shop",  emoji: "👓" },
  { name: "Lunettes de piscine", slot: "eyes", rarity: "common",   price_diamonds: 100,  source: "shop",  emoji: "🥽" },
  { name: "Masque de plongée",  slot: "eyes", rarity: "common",    price_diamonds: 110,  source: "shop",  emoji: "🤿" },
  { name: "Lunettes de star",   slot: "eyes", rarity: "rare",      price_diamonds: 250,  source: "shop",  emoji: "🕶️" },
  { name: "Cache-œil de pirate", slot: "eyes", rarity: "rare",     price_diamonds: 260,  source: "shop",  art: "eyepatch" },
  { name: "Visière du futur",   slot: "eyes", rarity: "epic",      price_diamonds: 550,  source: "shop",  art: "visor" },
  { name: "Monocle du mentor",  slot: "eyes", rarity: "legendary", price_diamonds: 1000, source: "shop",  art: "monocle" },
  # Cou — juste au-dessus de la base du fruit
  { name: "Cravate du dimanche", slot: "neck", rarity: "common",   price_diamonds: 90,   source: "shop",  emoji: "👔" },
  { name: "Écharpe de laine",   slot: "neck", rarity: "common",    price_diamonds: 100,  source: "shop",  emoji: "🧣" },
  { name: "Nœud papillon",      slot: "neck", rarity: "common",    price_diamonds: 100,  source: "shop",  art: "bowtie" },
  { name: "Dossard de course",  slot: "neck", rarity: "common",    price_diamonds: 110,  source: "shop",  art: "bib" },
  { name: "Collier de perles",  slot: "neck", rarity: "rare",      price_diamonds: 250,  source: "shop",  emoji: "📿" },
  { name: "Bandana",            slot: "neck", rarity: "rare",      price_diamonds: 240,  source: "shop",  art: "bandana" },
  { name: "Chaîne en or",       slot: "neck", rarity: "epic",      price_diamonds: 500,  source: "shop",  emoji: "🪙" },
  # Bras — un de chaque côté, à la largeur du fruit (le droit en miroir).
  # La pièce doit représenter UN bras : 🧤 et 🐾 sont des paires, ils sont dessinés.
  { name: "Gants d'hiver",      slot: "hands", rarity: "common",   price_diamonds: 90,   source: "shop",  art: "mitten" },
  { name: "Montre GPS",         slot: "hands", rarity: "rare",     price_diamonds: 250,  source: "shop",  emoji: "⌚" },
  { name: "Gants de boxe",      slot: "hands", rarity: "rare",     price_diamonds: 260,  source: "shop",  emoji: "🥊" },
  { name: "Bras mécanique",     slot: "hands", rarity: "epic",     price_diamonds: 520,  source: "shop",  emoji: "🦾" },
  { name: "Patte de loup",      slot: "hands", rarity: "epic",     price_diamonds: 550,  source: "shop",  art: "paw" },
  { name: "Baguette magique",   slot: "hands", rarity: "legendary", price_diamonds: 1000, source: "shop", art: "wand" },
  # Chaussures — une PAIRE vue de face sous le fruit
  { name: "Tongs",              slot: "shoes", rarity: "common",   price_diamonds: 90,   source: "shop",  emoji: "🩴" },
  { name: "Baskets de course",  slot: "shoes", rarity: "common",   price_diamonds: 110,  source: "shop",  art: "sneakers" },
  { name: "Chaussures de rando", slot: "shoes", rarity: "rare",    price_diamonds: 240,  source: "shop",  art: "trail" },
  { name: "Ballerines",         slot: "shoes", rarity: "rare",     price_diamonds: 250,  source: "shop",  art: "ballet" },
  { name: "Patins à glace",     slot: "shoes", rarity: "rare",     price_diamonds: 250,  source: "shop",  emoji: "⛸️" },
  { name: "Rollers dorés",      slot: "shoes", rarity: "epic",     price_diamonds: 500,  source: "shop",  art: "skates" },
  { name: "Bottes de sept lieues", slot: "shoes", rarity: "legendary", price_diamonds: 1000, source: "shop", art: "boots7" },
  # Accessoire — posé à côté du fruit
  { name: "Gourde",             slot: "sidekick", rarity: "common", price_diamonds: 90,  source: "shop",  emoji: "🥤" },
  { name: "Crotte porte-bonheur", slot: "sidekick", rarity: "common", price_diamonds: 90, source: "shop", emoji: "💩" },
  { name: "Barre protéinée",    slot: "sidekick", rarity: "common", price_diamonds: 100, source: "shop",  emoji: "🍫" },
  { name: "Banane de course",   slot: "sidekick", rarity: "common", price_diamonds: 110, source: "shop",  emoji: "🎒" },
  { name: "Maracas",            slot: "sidekick", rarity: "common", price_diamonds: 110, source: "shop",  emoji: "🪇" },
  { name: "Chien de course",    slot: "sidekick", rarity: "rare",  price_diamonds: 250,  source: "shop",  emoji: "🐕" },
  { name: "Chat supporter",     slot: "sidekick", rarity: "rare",  price_diamonds: 250,  source: "shop",  emoji: "🐈" },
  { name: "Paresseux",          slot: "sidekick", rarity: "rare",  price_diamonds: 250,  source: "shop",  emoji: "🦥" },
  { name: "Perroquet exotique", slot: "sidekick", rarity: "epic",  price_diamonds: 500,  source: "shop",  emoji: "🦜" },
  { name: "Chrono du coach",    slot: "sidekick", rarity: "epic",  price_diamonds: 520,  source: "shop",  emoji: "⏱️" },
  { name: "Sac de butin",       slot: "sidekick", rarity: "epic",  price_diamonds: 520,  source: "shop",  emoji: "💰" },
  { name: "Guépard",            slot: "sidekick", rarity: "epic",  price_diamonds: 550,  source: "shop",  emoji: "🐆" },
  # Auras — une couronne de 6 petits emojis, derrière le fruit
  { name: "Pétales de cerisier", slot: "aura", rarity: "common",   price_diamonds: 110,  source: "shop",  emoji: "🌸" },
  { name: "Aura pêche",         slot: "aura", rarity: "common",    price_diamonds: 120,  source: "shop",  emoji: "✨" },
  { name: "Double cœur",        slot: "aura", rarity: "common",    price_diamonds: 120,  source: "shop",  emoji: "💕" },
  { name: "Trèfle à quatre feuilles", slot: "aura", rarity: "rare", price_diamonds: 250, source: "shop",  emoji: "🍀" },
  { name: "Aura de givre",      slot: "aura", rarity: "rare",      price_diamonds: 250,  source: "shop",  emoji: "❄️" },
  { name: "Aura de feu",        slot: "aura", rarity: "epic",      price_diamonds: 550,  source: "shop",  emoji: "🔥" },
  { name: "Aura électrique",    slot: "aura", rarity: "epic",      price_diamonds: 550,  source: "shop",  emoji: "⚡" },
  { name: "Arc-en-ciel",        slot: "aura", rarity: "legendary", price_diamonds: 1000, source: "shop",  emoji: "🌈" },
  # Exclusives — jamais en vente (price nil) : tirages (streak, ligue), coffres, jours spéciaux
  { name: "Couronne de Noël",   slot: "hat",  rarity: "legendary", price_diamonds: nil,  source: "event", emoji: "👑" },
  { name: "Bonnet du Réveillon", slot: "hat", rarity: "epic",      price_diamonds: nil,  source: "event", art: "santa_hat" },
  { name: "Citrouille maudite", slot: "hat",  rarity: "epic",      price_diamonds: nil,  source: "event", emoji: "🎃" },
  { name: "Fantôme d'Halloween", slot: "sidekick", rarity: "epic", price_diamonds: nil,  source: "event", emoji: "👻" },
  { name: "Médaille d'Odyssea", slot: "neck", rarity: "legendary", price_diamonds: nil,  source: "rank",  emoji: "🏅" },
  { name: "Esprit du loup",     slot: "aura", rarity: "legendary", price_diamonds: nil,  source: "drop",  emoji: "🐺" },
  { name: "Ailes de dossard",   slot: "aura", rarity: "epic",      price_diamonds: nil,  source: "drop",  emoji: "🦋" },
])

puts "Objets (power-ups)…"
# Prix calibrés sur les données de la saison v1 (~10 🍑/semaine pour un actif médian).
# Le booster n'est plus un objet : c'est la jauge de meute (PackLevelJob), gagnée en courant.
Item.create!([
  { name: "Jambe de bois", price: 4, description: "Déjoue le prochain piège sur ta course",             effect_type: "wooden_leg" },
  { name: "Vent de dos",   price: 4, description: "×1,5 sur les boules de l'équipe pendant 12h",        effect_type: "back_wind" },
  { name: "Vent de face",  price: 4, description: "−25 % sur les boules adverses pendant 12h",          effect_type: "face_wind" },
  { name: "Chantilly",     price: 4, description: "Chantilly plein les yeux : masque les PV d'un monstre à l'équipe adverse (24h)", effect_type: "smoke" },
  { name: "Piège à loup",  price: 5, description: "Annule les boules de la prochaine course d'un adversaire", effect_type: "trap" },
  { name: "Saladier",      price: 6, description: "Saladier retourné sur ton monstre : intouchable pendant 6h", effect_type: "shield" },
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
    elevation_gain: rand(4..180), route_points: seed_route(distance_meters),
    sport_type: "Run", has_heartrate: true, average_heartrate: rand(132..168)
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
 ["Yann", "Écharpe de laine", true], ["Yann", "Chien de course", true],
 ["Inès", "Lunettes de star", true], ["Inès", "Gants de boxe", true],
 ["Chloé", "Haut-de-forme doré", false]].each do |name, cosmetic, on|
  user = User.find_by(firstname: name)
  UserCosmetic.create!(user:, cosmetic: Cosmetic.find_by(name: cosmetic),
                       equipped: on, acquired_at: 2.weeks.ago, source_game: game)
end

puts "Vitrine (un compte qui possède TOUT)…"
# Compte de démo pour juger le catalogue d'un coup d'œil : il possède les 45 pièces, donc
# l'écran /avatar les liste toutes, slot par slot, et on peut les essayer en un clic.
# Il ne court pas (0 km, 0 🍑) : il ne fausse ni la ligue ni la jauge de meute.
showcase = User.create!(firstname: "Vitrine", email: "vitrine@btb.test",
                        password: DEMO_PASSWORD, diamonds: 0)
Membership.create!(user: showcase, game:, team: exo, fruit: "ananas", balls: 0, role: "player",
                   weekly_streak: 0, best_streak: 0, streak_jokers: 0)
Cosmetic.find_each do |c|
  UserCosmetic.create!(user: showcase, cosmetic: c, equipped: false,
                       acquired_at: 1.day.ago, source_game: game)
end
# Une tenue complète équipée : une pièce par emplacement, les plus voyantes.
["Haut-de-forme doré", "Monocle du mentor", "Nœud papillon", "Gants de boxe",
 "Bottes de sept lieues", "Chien de course", "Arc-en-ciel"].each do |name|
  showcase.user_cosmetics.joins(:cosmetic).find_by(cosmetics: { name: })&.update!(equipped: true)
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
                                 route_points: seed_route(distance_meters),
                                 sport_type: "Run", has_heartrate: true, average_heartrate: rand(132..168))
  TrainingScorer.call(t)
  t.save!                   # la course a besoin d'un id : le piège mémorise qui l'a consommé
  ResolveRunEffects.call(t) # piège à loup / jambe de bois + notifs importantes aux deux camps
  t.save! if t.changed?
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
use_effect[ines, "shield"]              # 🥣 Inès (exo) : saladier sur King-Coco → secondaire à tous
use_effect[lea, "face_wind"]            # 🌪️ Léa (exo) : vent de face sur les rouges → notif importante aux victimes
# 🍦 Hugo (exo) barbouille les rouges et masque LEUR monstre (Framboitrix, target_team "foe") :
# les rouges voient les PV de Framboitrix en « ??? » et son avatar la chantilly plein les yeux
# (login max@btb.test), mais toujours les PV de King-Coco ; le chip 🍦 « Framboitrix masqué »
# s'affiche sur leur board. Yann (exo) voit tout, Framboitrix propre comme un sou neuf.
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

# 🚫 Deux sorties refusées par le contrôle anti-triche : personne ne valide à la main,
# TrainingPolicy tranche à l'import et le coureur reçoit la raison. La sortie reste visible
# sur son profil, avec le motif — mais elle ne rapporte rien et ne déclenche aucun piège.
seed_rejected = lambda do |membership, attrs|
  t = membership.trainings.build(date: 2.hours.ago, status: "verified", sport_type: "Run", **attrs)
  verdict = TrainingPolicy.call(t)
  t.assign_attributes(status: "rejected", rejection_reason: verdict.message, score: 0, base_balls: 0)
  t.save!
  Notification.create!(user: membership.user, game:, category: "training_rejected", importance: "important",
                       title: "Course non comptée", link: "/courses/#{t.id}",
                       body: "#{t.distance_km.round(1)} km · #{verdict.message}")
end

# Tapis sans preuve : ni cardio ni photo → « ajoute ta fréquence cardiaque ou une photo ».
seed_rejected[lea, { title: "Tapis de la salle", distance_meters: 5_400, moving_time: 1_950, trainer: true }]
# Trop lente (10:58 /km) : c'est de la marche.
seed_rejected[nico, { title: "Balade digestive", distance_meters: 4_100, moving_time: 2_700,
                      route_points: seed_route(4_100), has_heartrate: true, average_heartrate: 96 }]

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
puts "   Vitrine : vitrine@btb.test possède les #{Cosmetic.count} cosmétiques (écran /avatar)"
puts "👉 Connexion démo : yann@btb.test / #{DEMO_PASSWORD} " \
     "(Yann/exo voit tout — vents, saladier 🥣 sur King-Coco, chip 🍦 sur les rouges, second souffle " \
     "de Framboitrix, jauge de meute, 🍑 créditées, sa course dont le piège a été déjoué). " \
     "Se connecter en max@btb.test (rouges barbouillés) pour voir les PV masqués en « ??? » et " \
     "Framboitrix la chantilly plein les yeux."
