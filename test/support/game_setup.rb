# Petit décor de test : une partie active, deux équipes avec leur monstre, un joueur dans
# chaque camp. Utilisé par les tests d'import (anti-triche, quota, révocation).
module GameSetup
  def setup_game(starts_at: 3.months.ago, ends_at: 3.months.from_now)
    event = Event.create!(name: "Odyssea test", location: "Nantes", race_date: 6.months.from_now)
    @game = Game.create!(event:, name: "Partie test", status: "active", starts_at:, ends_at:)
    @exo = Team.create!(game: @game, name: "Exotiques", color: "#ffb703", fruit_family: "exotiques")
    @red = Team.create!(game: @game, name: "Rouges", color: "#e63946", fruit_family: "rouges")
    @exo.update!(opponent: @red)
    @red.update!(opponent: @exo)
    Monster.create!(team: @exo, name: "King-Coco", hp: GameRules::MONSTER_MAX_HP, max_hp: GameRules::MONSTER_MAX_HP)
    Monster.create!(team: @red, name: "Framboitrix", hp: GameRules::MONSTER_MAX_HP, max_hp: GameRules::MONSTER_MAX_HP)
    @membership = create_membership(@exo, "coureur")
    @foe = create_membership(@red, "adversaire")
  end

  def create_membership(team, name)
    user = User.create!(firstname: name.capitalize, email: "#{name}-#{SecureRandom.hex(4)}@btb.test",
                        password: "odyssea2027")
    Membership.create!(user:, game: @game, team:, balls: 0)
  end

  # Une activité Strava plausible : course extérieure de 8 km à 5:30 /km, avec cardio.
  def strava_activity(**overrides)
    {
      "id" => rand(1..10_000_000), "name" => "Sortie test", "type" => "Run", "sport_type" => "Run",
      "distance" => 8_000, "moving_time" => 2_640, "elapsed_time" => 2_700,
      "start_date" => 2.hours.ago.iso8601, "total_elevation_gain" => 42,
      "manual" => false, "trainer" => false, "flagged" => false,
      "has_heartrate" => true, "average_heartrate" => 148, "total_photo_count" => 0,
      "map" => { "summary_polyline" => "_p~iF~ps|U_ulLnnqC_mqNvxq`@" }
    }.merge(overrides.transform_keys(&:to_s))
  end

  def build_training(**attrs)
    defaults = { date: 2.hours.ago, distance_meters: 8_000, moving_time: 2_640, elapsed_time: 2_700,
                 status: "verified", sport_type: "Run", route_points: [ [ 47.2, -1.5 ], [ 47.3, -1.6 ] ] }
    @membership.trainings.build(**defaults, **attrs)
  end
end
