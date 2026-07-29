require "test_helper"

class TrainingTest < ActiveSupport::TestCase
  setup do
    @game = create_game
    @m = create_player(@game, @game.teams.first, balls: 0)
  end

  test "les boules sont créditées une seule fois" do
    training = create_training(@m, km: 8)

    assert_equal 8, training.credit_balls!
    assert_equal 8, @m.reload.balls
    assert_nil training.credit_balls!
    assert_equal 8, @m.reload.balls
  end

  test "le porte-monnaie est plafonné, la course garde son score" do
    @m.update!(balls: GameRules::WALLET_CAP - 3)
    training = create_training(@m, km: 10)

    assert_equal 3, training.credit_balls!
    assert_equal GameRules::WALLET_CAP, @m.reload.balls
    assert_equal 10, training.score.to_i
  end

  test "une course piégée ne verse rien" do
    training = create_training(@m, km: 8, status: "trapped", score: 0)

    assert_nil training.credit_balls!
    assert_equal 0, @m.reload.balls
  end

  test "seules les courses qui comptent entrent dans scoring" do
    create_training(@m, km: 5, status: "verified")
    create_training(@m, km: 5, status: "protected")
    create_training(@m, km: 5, status: "pending")
    create_training(@m, km: 5, status: "trapped")

    assert_equal 2, @m.trainings.scoring.count
  end

  test "l'allure se calcule en secondes par km" do
    training = create_training(@m, km: 10)
    training.update!(moving_time: 3_000)

    assert_equal 300, training.pace_seconds
  end
end
