# Jeu de données de démonstration — valide le schéma et sert d'exemple.
puts "Nettoyage…"
[Reward, Chest, Message, Conversation, Notification, PushSubscription,
 Action, MembershipItem, Training, TeamEffect, Membership, Monster, Team,
 SpecialDay, Game, Event, UserCosmetic, Cosmetic, Avatar, Item, User].each(&:delete_all)

puts "Cosmétiques…"
Cosmetic.create!([
  { name: "Haut-de-forme doré", slot: "hat",  rarity: "legendary", price_diamonds: 300, source: "shop" },
  { name: "Casquette",          slot: "hat",  rarity: "rare",      price_diamonds: 90,  source: "shop" },
  { name: "Lunettes de star",   slot: "eyes", rarity: "epic",      price_diamonds: 150, source: "shop" },
  { name: "Aura pêche",         slot: "aura", rarity: "common",    price_diamonds: 50,  source: "shop" },
  { name: "Couronne de Noël",   slot: "hat",  rarity: "legendary", price_diamonds: nil, source: "event" },
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
                     starts_at: 1.week.ago, ends_at: 8.weeks.from_now)

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
week_start = Date.current.beginning_of_week
days_elapsed = (Date.current - week_start).to_i
[["Yann","citron"],["Léa","citron"],["Nico","citron"],
 ["Max","fraise"],["Chloé","fraise"],["Sam","fraise"]].each_with_index do |(name, side), i|
  user = User.create!(firstname: name, email: "#{name.downcase.tr('é','e')}@btb.test", diamonds: i * 8)
  Avatar.create!(user:, base_color: side)
  team = side == "citron" ? citron : fraise
  # La majorité en Bronze pour qu'un compte fraîchement créé ait du monde dans sa division.
  division, last_rank, last_result = [[1, 2, "promoted"], [0, 4, "stayed"], [0, 5, "stayed"],
                                      [0, 3, "stayed"], [0, 6, "stayed"], [1, 1, "promoted"]][i]
  m = Membership.create!(user:, game:, team:, balls: 14 - i, weekly_streak: [3,2,1].sample,
                         role: (i.zero? ? "admin" : "player"),
                         division:, last_league_rank: last_rank, last_league_result: last_result)
  # Courses réparties dans la semaine EN COURS, pour que la ligue ne soit pas vide.
  3.times do |d|
    day = week_start + (d % (days_elapsed + 1))
    Training.create!(membership: m, date: day.to_time + 8.hours, distance_meters: rand(4000..12000),
                     score: rand(4..10), status: "verified")
  end
end

first = Membership.first
Chest.create!(membership: first, rarity: "epic", reward_diamonds: 35,
              cosmetic: Cosmetic.find_by(name: "Haut-de-forme doré"))
Notification.create!(user: first.user, game:, category: "chest",
                     title: "Tu as trouvé un coffre épique", body: "Ouvre-le pour tes récompenses !")

puts "OK — #{User.count} joueurs, #{Training.count} courses, #{Team.count} équipes, #{Cosmetic.count} cosmétiques."
