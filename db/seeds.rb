# Jeu de données de démonstration — valide le schéma et sert d'exemple.
puts "Nettoyage…"
[Reward, Chest, Message, Conversation, Notification, PushSubscription,
 Action, MembershipItem, Training, TeamEffect, Membership, Monster, Team,
 SpecialDay, Game, Event, UserCosmetic, Cosmetic, Avatar, Item, User].each(&:delete_all)

puts "Cosmétiques…"
Cosmetic.create!([
  { name: "Haut-de-forme doré", slot: "hat",  rarity: "legendary", price_diamonds: 300, source: "shop",  emoji: "🎩" },
  { name: "Casquette",          slot: "hat",  rarity: "rare",      price_diamonds: 90,  source: "shop",  emoji: "🧢" },
  { name: "Bandeau",            slot: "hat",  rarity: "common",    price_diamonds: 40,  source: "shop",  emoji: "🎀" },
  { name: "Lunettes de star",   slot: "eyes", rarity: "epic",      price_diamonds: 150, source: "shop",  emoji: "🕶️" },
  { name: "Lunettes rondes",    slot: "eyes", rarity: "common",    price_diamonds: 45,  source: "shop",  emoji: "👓" },
  { name: "Aura pêche",         slot: "aura", rarity: "common",    price_diamonds: 50,  source: "shop",  emoji: "✨" },
  { name: "Aura de feu",        slot: "aura", rarity: "epic",      price_diamonds: 180, source: "shop",  emoji: "🔥" },
  { name: "Couronne de Noël",   slot: "hat",  rarity: "legendary", price_diamonds: nil, source: "event", emoji: "👑" },
])

puts "Objets (power-ups)…"
Item.create!([
  { name: "Booster ×2",   price: 8,  description: "24h de dégâts et soins doublés",    effect_type: "booster" },
  { name: "Vent de dos",  price: 6,  description: "Bonus de pêches sur l'équipe",      effect_type: "back_wind" },
  { name: "Piège à loup", price: 5,  description: "Annule les pêches d'un adversaire", effect_type: "trap" },
  { name: "Bouclier",     price: 10, description: "Protège ton monstre 3h",           effect_type: "shield" },
])

puts "Event + partie…"
event = Event.create!(name: "Odyssea Nantes", race_date: Date.new(2027, 3, 15), location: "Nantes")
game  = Game.create!(event:, name: "Partie Odyssea 2027", status: "active",
                     starts_at: 7.weeks.ago, ends_at: 8.weeks.from_now)

citron = Team.create!(game:, name: "Zeste Solaire",  color: "#f2b100")
fraise = Team.create!(game:, name: "Chair Écarlate", color: "#f0325b")
citron.update!(opponent: fraise); fraise.update!(opponent: citron)

Monster.create!(team: citron, name: "Citronator", hp: 720, max_hp: 1000, state: "hurt")
Monster.create!(team: fraise, name: "Fraizilla",  hp: 340, max_hp: 1000, state: "critical")

Conversation.create!(game:, kind: "general")
Conversation.create!(game:, kind: "team", team: citron)
Conversation.create!(game:, kind: "team", team: fraise)

SpecialDay.create!(game:, name: "Noël", date: Date.new(2026, 12, 25), multiplier: 2)

puts "Joueurs…"
weeks_of_history = 6 # semaines de courses passées, en plus de la semaine en cours

week_start   = Date.current.beginning_of_week
days_elapsed = (Date.current - week_start).to_i

# Deux équipes complètes de 5. `runs` = sorties/semaine, `km` = distance typique d'une sortie :
# de quoi produire des profils de coureurs différents (assidus, occasionnels, gros volumes).
# `face` : style de personnage de l'avatar (Avatar::BODY_STYLES).
roster = [
  { name: "Yann",  side: "citron", runs: 4, km: 6..11, face: "sporty",  role: "admin" },
  { name: "Léa",   side: "citron", runs: 3, km: 5..9,  face: "default" },
  { name: "Nico",  side: "citron", runs: 2, km: 4..7,  face: "zen" },
  { name: "Inès",  side: "citron", runs: 5, km: 7..14, face: "sporty" },
  { name: "Hugo",  side: "citron", runs: 1, km: 3..6,  face: "ghost" },
  { name: "Max",   side: "fraise", runs: 3, km: 6..10, face: "beast" },
  { name: "Chloé", side: "fraise", runs: 4, km: 8..13, face: "sporty" },
  { name: "Sam",   side: "fraise", runs: 2, km: 4..8,  face: "robot" },
  { name: "Anaïs", side: "fraise", runs: 3, km: 5..12, face: "default" },
  { name: "Théo",  side: "fraise", runs: 1, km: 9..15, face: "zen" }
]

# Une sortie, scorée avec la vraie règle du jeu (1 km = 1 🍑, plafond 10, × jour spécial).
def seed_training!(membership, day, distance_meters)
  training = Training.new(membership:, date: day.to_time + rand(7..19).hours,
                          distance_meters:, status: "verified")
  TrainingScorer.call(training)
  training.save!
end

roster.each do |p|
  user = User.create!(firstname: p[:name], diamonds: rand(0..60),
                      email: "#{p[:name].downcase.tr('éèàï', 'eeai')}@btb.test")
  Avatar.create!(user:, base_color: p[:side], body_style: p[:face])
  team = p[:side] == "citron" ? citron : fraise
  m = Membership.create!(user:, game:, team:, balls: rand(4..18),
                         role: p[:role] || "player", weekly_streak: [weeks_of_history, p[:runs] * 2].min,
                         best_streak: weeks_of_history, last_streak_week: week_start)

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
Notification.create!(user: first.user, game:, category: "chest",
                     title: "Tu as trouvé un coffre épique", body: "Ouvre-le pour tes récompenses !")

puts "Cosmétiques possédés…"
# De quoi voir l'écran avatar rempli sans avoir à gagner un mois de classement.
[["Yann", "Casquette", true], ["Yann", "Aura de feu", true],
 ["Inès", "Lunettes de star", true], ["Chloé", "Haut-de-forme doré", false]].each do |name, cosmetic, on|
  user = User.find_by(firstname: name)
  UserCosmetic.create!(user:, cosmetic: Cosmetic.find_by(name: cosmetic),
                       equipped: on, acquired_at: 2.weeks.ago, source_game: game)
end

puts "Messages…"
general = game.general_conversation
[["Yann", "Allez les jaunes, on a un mois à gagner 🍋"],
 ["Chloé", "Vous allez pleurer, Fraizilla a faim 🍓"],
 ["Inès", "10 km ce matin, Citronator vous salue"],
 ["Théo", "Qui court demain matin ?"]].each_with_index do |(name, body), i|
  m = Membership.joins(:user).find_by(users: { firstname: name })
  Message.create!(conversation: general, membership: m, body:, created_at: (4 - i).hours.ago)
end

game.conversations.team_chats.find_each do |conv|
  conv.team.memberships.limit(2).each_with_index do |m, i|
    Message.create!(conversation: conv, membership: m, created_at: (2 - i).hours.ago,
                    body: i.zero? ? "On concentre les attaques ce soir ?" : "Ok, je garde mes pêches 🍑")
  end
end

puts "OK — #{User.count} joueurs, #{Training.count} courses sur #{weeks_of_history + 1} semaines, " \
     "#{Team.count} équipes, #{Cosmetic.count} cosmétiques."
Team.all.each do |t|
  km = Training.where(membership: t.memberships).sum(:distance_meters) / 1000.0
  puts "   #{t.name} : #{t.memberships.count} joueurs, #{km.round} km cumulés"
end
