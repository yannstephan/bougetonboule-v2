require "test_helper"
require "support/game_setup"

class TrainingPolicyTest < ActiveSupport::TestCase
  include GameSetup

  setup { setup_game }

  test "une course à pied normale passe" do
    assert TrainingPolicy.call(build_training).ok?
  end

  test "refuse ce qui n'est pas une course à pied" do
    verdict = TrainingPolicy.call(build_training(sport_type: "Ride"))
    assert_equal :sport_type, verdict.code
  end

  test "refuse une activité saisie à la main" do
    assert_equal :manual, TrainingPolicy.call(build_training(manual: true)).code
  end

  test "refuse une activité signalée par Strava" do
    assert_equal :flagged, TrainingPolicy.call(build_training(flagged: true)).code
  end

  test "refuse moins de 2 km" do
    assert_equal :too_short, TrainingPolicy.call(build_training(distance_meters: 1_900)).code
  end

  test "refuse une distance invraisemblable" do
    assert_equal :too_long, TrainingPolicy.call(build_training(distance_meters: 90_000, moving_time: 30_000)).code
  end

  test "refuse une allure de marche" do
    # 8 km en 1h20 = 10:00 /km
    assert_equal :too_slow, TrainingPolicy.call(build_training(moving_time: 4_800)).code
  end

  test "une séance rapide passe (3:20 /km)" do
    assert TrainingPolicy.call(build_training(moving_time: 1_600)).ok?
  end

  test "refuse une allure de vélo" do
    # 8 km en 20 min = 2:30 /km
    assert_equal :too_fast, TrainingPolicy.call(build_training(moving_time: 1_200)).code
  end

  test "refuse une course sans durée" do
    assert_equal :no_time, TrainingPolicy.call(build_training(moving_time: nil, elapsed_time: nil)).code
  end

  test "refuse une course de plus de 7 jours" do
    assert_equal :too_old, TrainingPolicy.call(build_training(date: 8.days.ago)).code
  end

  test "refuse une course datée dans le futur" do
    assert_equal :future, TrainingPolicy.call(build_training(date: 3.hours.from_now)).code
  end

  test "tapis sans tracé : refusé sans cardio ni photo" do
    training = build_training(route_points: [], trainer: true)
    assert_equal :no_proof, TrainingPolicy.call(training).code
  end

  test "tapis sans tracé : accepté avec la fréquence cardiaque" do
    training = build_training(route_points: [], trainer: true, has_heartrate: true, average_heartrate: 152)
    assert TrainingPolicy.call(training).ok?
  end

  test "tapis sans tracé : accepté avec une photo" do
    training = build_training(route_points: [], trainer: true, photo_count: 1)
    assert TrainingPolicy.call(training).ok?
  end

  test "tapis sans tracé : une cardio absurde ne suffit pas" do
    training = build_training(route_points: [], trainer: true, has_heartrate: true, average_heartrate: 40)
    assert_equal :no_proof, TrainingPolicy.call(training).code
  end

  test "refuse une activité déjà importée par un autre joueur" do
    @foe.trainings.create!(strava_activity_id: "42", date: 2.hours.ago, distance_meters: 8_000,
                           moving_time: 2_640, status: "verified")
    assert_equal :claimed, TrainingPolicy.call(build_training(strava_activity_id: "42")).code
  end

  test "la même activité peut compter dans deux parties du même joueur" do
    other_game = Game.create!(event: @game.event, name: "Autre partie", status: "active",
                              starts_at: 1.month.ago, ends_at: 2.months.from_now)
    other_team = Team.create!(game: other_game, name: "Exo bis", color: "#fff", fruit_family: "exotiques")
    elsewhere = Membership.create!(user: @membership.user, game: other_game, team: other_team)
    elsewhere.trainings.create!(strava_activity_id: "42", date: 2.hours.ago, distance_meters: 8_000,
                                moving_time: 2_640, status: "verified")

    assert TrainingPolicy.call(build_training(strava_activity_id: "42")).ok?
  end

  test "refuse le doublon montre + téléphone" do
    start = 2.hours.ago
    @membership.trainings.create!(date: start, distance_meters: 8_000, moving_time: 2_640,
                                  elapsed_time: 2_700, status: "verified")
    duplicate = build_training(date: start + 30.seconds, moving_time: 2_600, elapsed_time: 2_650)

    assert_equal :duplicate, TrainingPolicy.call(duplicate).code
  end

  test "deux sorties distinctes dans la même journée passent" do
    @membership.trainings.create!(date: 8.hours.ago, distance_meters: 8_000, moving_time: 2_640,
                                  elapsed_time: 2_700, status: "verified")
    assert TrainingPolicy.call(build_training).ok?
  end
end
