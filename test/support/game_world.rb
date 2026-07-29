# Monte une partie jouable en mémoire : un event, une partie active, deux équipes avec leur
# monstre et leurs conversations, et autant de joueurs qu'on veut. C'est le db/seeds.rb du
# test — en beaucoup plus petit.
module GameWorld
  PASSWORD = "motdepasse"

  def create_game(status: "active")
    event = Event.create!(name: "Odyssea", location: "Nantes", race_date: 6.months.from_now)
    game = Game.create!(event:, name: "Saison test", status:,
                        starts_at: 30.days.ago, ends_at: 60.days.from_now)
    exo = create_team(game, "Exotiques", "exotiques", "King-Coco")
    red = create_team(game, "Rouges", "rouges", "Framboitrix")
    exo.update!(opponent: red)
    red.update!(opponent: exo)
    Conversation.create!(game:, kind: "general")
    game
  end

  def create_team(game, name, family, monster)
    team = Team.create!(game:, name:, fruit_family: family, color: "#ff7a59")
    Monster.create!(team:, name: monster, hp: GameRules::MONSTER_MAX_HP,
                    max_hp: GameRules::MONSTER_MAX_HP)
    Conversation.create!(game:, kind: "team", team:)
    team
  end

  def create_player(game, team, firstname: "Joueur", balls: 20, **attrs)
    user = User.create!(firstname:, email: "#{firstname.downcase}-#{SecureRandom.hex(4)}@btb.test",
                        password: PASSWORD)
    Membership.create!(user:, game:, team:, balls:, fruit: team.fruit_keys.first, **attrs)
  end

  def create_training(membership, km: 5, date: Time.current, status: "verified", score: nil)
    membership.trainings.create!(date:, distance_meters: (km * 1000).to_i, status:,
                                 score: score || [km.floor, GameRules::MAX_BALLS_PER_RUN].min)
  end

  def sign_in_as(user)
    post login_path, params: { email: user.email, password: PASSWORD }
  end

  # Rejoue un bloc avec une constante d'équilibrage forcée (ex. supprimer l'aléatoire de
  # l'échec critique pour tester les deux branches d'une attaque).
  def with_rule(name, value)
    previous = GameRules.const_get(name)
    GameRules.send(:remove_const, name)
    GameRules.const_set(name, value)
    yield
  ensure
    GameRules.send(:remove_const, name)
    GameRules.const_set(name, previous)
  end
end
