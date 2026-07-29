require "test_helper"

class TrainingScorerTest < ActiveSupport::TestCase
  setup do
    @game = create_game
    @team = @game.teams.first
    @m = create_player(@game, @team)
  end

  test "1 km = 1 boule, plafonné" do
    assert_equal 7, score_for(km: 7.9)
    assert_equal GameRules::MAX_BALLS_PER_RUN, score_for(km: 42)
  end

  test "un jour spécial double aussi le plafond" do
    @game.special_days.create!(name: "Halloween", date: Date.current, multiplier: 2)

    assert_equal 20, score_for(km: 15)
  end

  test "un vent de dos multiplie, un vent de face réduit" do
    @team.team_effects.create!(kind: "back_wind", modifier: GameRules::BACK_WIND_MODIFIER,
                               expires_at: 6.hours.from_now)
    assert_equal 15, score_for(km: 12)

    @team.team_effects.create!(kind: "face_wind", modifier: GameRules::FACE_WIND_MODIFIER,
                               expires_at: 6.hours.from_now)
    assert_equal 11, score_for(km: 12) # 10 × 1,5 × 0,75 = 11,25 → 11
  end

  test "une course importée en retard est jugée à sa date réelle" do
    @team.team_effects.create!(kind: "back_wind", modifier: GameRules::BACK_WIND_MODIFIER,
                               created_at: 3.days.ago, expires_at: 3.days.ago + 12.hours)

    assert_equal 10, score_for(km: 10, date: Time.current)         # vent expiré
    assert_equal 15, score_for(km: 10, date: 3.days.ago + 1.hour)  # vent actif ce jour-là
  end

  private

  def score_for(km:, date: Time.current)
    training = @m.trainings.build(date:, distance_meters: (km * 1000).to_i, status: "verified")
    TrainingScorer.call(training).score.to_i
  end
end
