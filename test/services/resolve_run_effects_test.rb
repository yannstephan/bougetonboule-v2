require "test_helper"

class ResolveRunEffectsTest < ActiveSupport::TestCase
  setup do
    @game = create_game
    @exo, @red = @game.teams.to_a
    @runner = create_player(@game, @exo, firstname: "Yann")
    @trapper = create_player(@game, @red, firstname: "Chloé")
    @trap = Item.create!(name: "Piège à loup", effect_type: "trap", price: 5)
    @leg = Item.create!(name: "Jambe de bois", effect_type: "wooden_leg", price: 4)
  end

  test "un piège annule la course et ses boules" do
    lay(@trap, @trapper, target: @runner)
    training = scored_training

    ResolveRunEffects.call(training)

    assert_equal "trapped", training.status
    assert_equal 0, training.score
    assert Action.find_by(item: @trap).resolved_at.present?
  end

  test "une jambe de bois déjoue le piège et sauve les boules" do
    lay(@leg, @runner)
    lay(@trap, @trapper, target: @runner)
    training = scored_training

    ResolveRunEffects.call(training)

    assert_equal "protected", training.status
    assert_equal 8, training.score.to_i
    assert Action.find_by(item: @leg).resolved_at.present?
  end

  test "un piège posé après la course ne se referme pas dessus" do
    training = scored_training(date: 2.days.ago)
    lay(@trap, @trapper, target: @runner)

    ResolveRunEffects.call(training)

    assert_equal "verified", training.status
  end

  test "un piège ne sert qu'une fois" do
    lay(@trap, @trapper, target: @runner)
    ResolveRunEffects.call(scored_training)

    second = scored_training
    ResolveRunEffects.call(second)
    assert_equal "verified", second.status
  end

  private

  def lay(item, membership, target: nil)
    Action.create!(game: @game, membership:, item:, action_type: "use_item",
                   target:, created_at: 1.hour.ago)
  end

  def scored_training(date: Time.current)
    @runner.trainings.create!(date:, distance_meters: 8_000, status: "verified", score: 8)
  end
end
