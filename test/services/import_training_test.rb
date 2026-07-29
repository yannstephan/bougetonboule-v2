require "test_helper"
require "support/game_setup"

class ImportTrainingTest < ActiveSupport::TestCase
  include GameSetup

  setup { setup_game }

  test "une course conforme est comptée et créditée" do
    training = ImportTraining.call(@membership, strava_activity)

    assert_equal "verified", training.status
    assert_equal 8, training.score.to_i
    assert_equal 8, @membership.reload.balls
  end

  test "une course non conforme est enregistrée sans rien rapporter" do
    training = ImportTraining.call(@membership, strava_activity(sport_type: "Ride"))

    assert_equal "rejected", training.status
    assert_match "course à pied", training.rejection_reason
    assert_equal 0, training.score.to_i
    assert_equal 0, @membership.reload.balls
  end

  test "une course non conforme ne fait pas claquer le piège à loup" do
    trap = arm_trap!

    ImportTraining.call(@membership, strava_activity(distance: 1_500, moving_time: 500))

    assert_nil trap.reload.resolved_at
  end

  test "le quota journalier plafonne à 10 boules de base" do
    ImportTraining.call(@membership, strava_activity(distance: 12_000, moving_time: 3_960))
    second = ImportTraining.call(@membership, strava_activity(distance: 9_000, moving_time: 2_970,
                                                              start_date: 30.minutes.ago.iso8601))

    assert_equal 10, @membership.trainings.scoring.sum(:base_balls)
    assert_equal 0, second.score.to_i
    assert_equal 10, @membership.reload.balls
  end

  test "le quota journalier se remet à zéro le lendemain" do
    ImportTraining.call(@membership, strava_activity(distance: 12_000, moving_time: 3_960,
                                                     start_date: 26.hours.ago.iso8601))
    today = ImportTraining.call(@membership, strava_activity)

    assert_equal 8, today.score.to_i
    assert_equal 18, @membership.reload.balls
  end

  test "réimporter la même activité ne crédite pas deux fois" do
    activity = strava_activity
    ImportTraining.call(@membership, activity)
    ImportTraining.call(@membership, activity)

    assert_equal 1, @membership.trainings.count
    assert_equal 8, @membership.reload.balls
  end

  test "une photo ajoutée après coup fait entrer la course sur tapis" do
    treadmill = strava_activity(trainer: true, has_heartrate: false, average_heartrate: nil,
                                map: { "summary_polyline" => nil })
    rejected = ImportTraining.call(@membership, treadmill)
    assert_equal "rejected", rejected.status
    assert_equal 0, @membership.reload.balls

    accepted = ImportTraining.call(@membership, treadmill.merge("total_photo_count" => 1))

    assert_equal "verified", accepted.status
    assert_equal 8, @membership.reload.balls
  end

  test "doublon montre + téléphone : c'est la trace la plus longue qui reste" do
    short = ImportTraining.call(@membership, strava_activity(distance: 5_000, moving_time: 1_650,
                                                             elapsed_time: 1_700))
    assert_equal 5, @membership.reload.balls

    long = ImportTraining.call(@membership, strava_activity(distance: 8_000, moving_time: 2_640,
                                                            elapsed_time: 2_700))

    assert_equal "rejected", short.reload.status
    assert_equal "verified", long.status
    assert_equal 8, @membership.reload.balls
  end

  test "une course requalifiée en vélo est retirée et les boules reprises" do
    activity = strava_activity
    ImportTraining.call(@membership, activity)
    assert_equal 8, @membership.reload.balls

    training = ImportTraining.call(@membership, activity.merge("sport_type" => "Ride"))

    assert_equal "rejected", training.status
    assert_equal 0, training.score.to_i
    assert_equal 0, @membership.reload.balls
  end

  test "supprimer une course sur Strava réarme le piège à loup" do
    trap = arm_trap!
    training = ImportTraining.call(@membership, strava_activity)
    assert_equal "trapped", training.status
    assert_equal training.id, trap.reload.resolved_training_id

    RevokeTraining.call(training, reason: "Course supprimée sur Strava.")

    assert_nil trap.reload.resolved_at
    assert_nil trap.resolved_training_id
  end

  test "la reprise des boules ne met jamais le solde en négatif" do
    training = ImportTraining.call(@membership, strava_activity)
    @membership.update!(balls: 3) # le joueur a déjà dépensé

    RevokeTraining.call(training, reason: "Course supprimée sur Strava.")

    assert_equal 0, @membership.reload.balls
  end

  private

  def arm_trap!
    item = Item.create!(name: "Piège à loup", effect_type: "trap", price: 5)
    Action.create!(game: @game, membership: @foe, item:, action_type: "use_item",
                   target: @membership, created_at: 3.days.ago)
  end
end
