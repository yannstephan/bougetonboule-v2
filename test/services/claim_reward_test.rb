require "test_helper"
require "support/game_setup"

# Les gains de série sont POSÉS par WeeklyStreakJob et ENCAISSÉS par le joueur. Ce test
# verrouille la frontière : rien n'est crédité tant qu'on n'a pas réclamé, et réclamer deux
# fois ne paie qu'une fois.
class ClaimRewardTest < ActiveSupport::TestCase
  include GameSetup

  setup do
    setup_game
    @user = @membership.user
  end

  test "courir sécurise la semaine tout de suite, sans attendre le lundi" do
    assert_difference -> { Reward.pending.count }, 1 do
      ImportTraining.call(@membership, strava_activity)
    end
    assert_equal 1, @membership.reload.weekly_streak
    assert_equal Date.current.beginning_of_week, @membership.last_streak_week
    assert_equal 1, Reward.last.streak_week
    assert_equal 0, @user.reload.diamonds, "posé, pas crédité : il faut venir le réclamer"
  end

  test "deux courses la même semaine ne comptent qu'une fois" do
    ImportTraining.call(@membership, strava_activity)

    assert_no_difference -> { Reward.pending.count } do
      ImportTraining.call(@membership, strava_activity(id: 987_654))
    end
    assert_equal 1, @membership.reload.weekly_streak
  end

  test "le lundi rattrape une semaine avec course que l'import aurait ratée" do
    run_last_week! # course posée sans passer par ImportTraining

    assert_difference -> { Reward.pending.count }, 1 do
      WeeklyStreakJob.perform_now
    end
    assert_equal 1, @membership.reload.weekly_streak
  end

  test "le lundi ne recompte pas une semaine déjà sécurisée à l'import" do
    ImportTraining.call(@membership, strava_activity(start_date: 3.days.ago.iso8601))
    before = @membership.reload.weekly_streak

    assert_no_difference -> { Reward.count } do
      WeeklyStreakJob.perform_now(Date.current.beginning_of_week)
    end
    assert_equal before, @membership.reload.weekly_streak
  end

  test "réclamer crédite une fois, et une seule" do
    ImportTraining.call(@membership, strava_activity)
    reward = @membership.rewards.pending.first

    result = ClaimReward.call(@membership, reward)
    assert result.ok
    assert_equal GameRules::STREAK_LADDER.first, @user.reload.diamonds
    assert_not reward.reload.pending?

    again = ClaimReward.call(@membership, reward)
    assert_not again.ok
    assert_equal GameRules::STREAK_LADDER.first, @user.reload.diamonds
  end

  test "on ne réclame pas le gain d'un autre joueur" do
    ImportTraining.call(@membership, strava_activity)
    reward = @membership.rewards.pending.first

    result = ClaimReward.call(@foe, reward)
    assert_not result.ok
    assert reward.reload.pending?
  end

  test "le cosmétique du palier attend lui aussi, et compense s'il est déjà possédé" do
    cosmetic = Cosmetic.create!(name: "Bob test", slot: "hat", rarity: "common", emoji: "🎩")
    @membership.update_columns(weekly_streak: GameRules::STREAK_MILESTONE_EVERY - 1)
    ImportTraining.call(@membership, strava_activity)

    gift = @membership.rewards.pending.find_by(source: "streak_gift")
    assert gift, "le palier doit poser un cadeau en attente"
    assert_equal 0, @user.user_cosmetics.count, "rien n'est versé avant la réclamation"

    # Le joueur l'obtient autrement entre-temps : on compense en 💎 plutôt qu'un doublon.
    @user.user_cosmetics.create!(cosmetic: gift.cosmetic, acquired_at: Time.current) if gift.cosmetic
    before = @user.reload.diamonds
    assert ClaimReward.call(@membership, gift).ok
    assert_operator @user.reload.diamonds, :>, before
    assert_equal 1, @user.user_cosmetics.where(cosmetic_id: cosmetic.id).count if gift.cosmetic_id == cosmetic.id
  end

  test "le joker du palier, lui, tombe tout de suite" do
    @membership.update_columns(weekly_streak: GameRules::STREAK_MILESTONE_EVERY - 1)

    ImportTraining.call(@membership, strava_activity)
    assert_equal 1, @membership.reload.streak_jokers,
                 "le joker est un bouclier : le faire attendre ferait perdre des séries"
  end

  test "une course arrivée en retard ne rouvre pas une semaine déjà jugée" do
    @membership.update_columns(weekly_streak: 3, streak_jokers: 1)
    WeeklyStreakJob.perform_now # semaine écoulée sans course : un joker part
    assert_equal 0, @membership.reload.streak_jokers

    # La course de cette semaine-là arrive après coup : elle ne doit pas rendre le joker.
    assert_no_difference -> { Reward.count } do
      ImportTraining.call(@membership, strava_activity(start_date: (Date.current.beginning_of_week - 5).to_time.iso8601))
    end
    assert_equal 3, @membership.reload.weekly_streak
    assert_equal 0, @membership.streak_jokers
  end

  # La PREMIÈRE course de la semaine suffit : ce qu'elle rapporte n'entre pas en compte.
  # Testé sur la règle elle-même — passer par l'import ferait intervenir le plafond journalier
  # et la détection de doublon, qui ne sont pas le sujet.
  test "une sortie à 0 🍑 (plafond du jour) sécurise quand même la semaine" do
    training = build_training(date: Time.zone.now, status: "verified", score: 0, base_balls: 0)
    training.save!

    assert AdvanceStreak.for_training(training)
    assert_equal 1, @membership.reload.weekly_streak
  end

  test "une course piégée sécurise la semaine — le loup vole les 🍑, pas la série" do
    training = build_training(date: Time.zone.now, status: "trapped", score: 0)
    training.save!

    assert AdvanceStreak.for_training(training)
    assert_equal 1, @membership.reload.weekly_streak,
                 "un piège à 5 🍑 ne doit pas casser une série de 20 semaines"
  end

  test "une course refusée par l'anti-triche ne sécurise rien" do
    training = build_training(date: Time.zone.now, status: "rejected", score: 0)
    training.save!

    assert_not AdvanceStreak.for_training(training)
    assert_equal 0, @membership.reload.weekly_streak
  end

  # Régression : à la 5e semaine on reste SUR le cycle 1..5. Sans ça le gain du palier
  # quittait la piste à la seconde où on le gagnait, et devenait inatteignable.
  test "le palier reste sur la piste tant qu'il n'est pas encaissé" do
    @membership.update_columns(weekly_streak: GameRules::STREAK_MILESTONE_EVERY - 1)
    ImportTraining.call(@membership, strava_activity)

    pass = StreakPassPresenter.call(@membership.reload)
    milestone = pass[:nodes].find { |n| n[:milestone] }

    assert_equal 1, pass[:nodes].first[:week], "on doit encore voir le cycle 1..5"
    assert_equal GameRules::STREAK_MILESTONE_EVERY, milestone[:week]
    assert_equal "claimable", milestone[:state]
    assert_equal 2, milestone[:pending], "les 💎 ET le cadeau attendent sur ce nœud"
  end

  test "on passe au cycle suivant une fois le palier dépassé" do
    @membership.update_columns(weekly_streak: GameRules::STREAK_MILESTONE_EVERY)
    ImportTraining.call(@membership, strava_activity)

    pass = StreakPassPresenter.call(@membership.reload)
    assert_equal GameRules::STREAK_MILESTONE_EVERY + 1, pass[:nodes].first[:week]
  end

  # Régression : le bouton encaissait les 💎 et oubliait le cadeau du palier.
  test "encaisser un palier prend les deux gains d'un coup" do
    @membership.update_columns(weekly_streak: GameRules::STREAK_MILESTONE_EVERY - 1)
    ImportTraining.call(@membership, strava_activity)
    week = @membership.reload.weekly_streak

    assert_equal 2, @membership.rewards.pending.streak.where(streak_week: week).count
    @membership.rewards.pending.streak.where(streak_week: week).order(:id).each do |r|
      assert ClaimReward.call(@membership, r).ok
    end
    assert_equal 0, @membership.rewards.pending.count, "plus rien ne doit rester en attente"
  end

  private

  # Une course scorée dans la semaine écoulée, celle que le job juge.
  def run_last_week!
    build_training(date: Date.current.beginning_of_week - 5, status: "verified", score: 8).save!
  end
end
