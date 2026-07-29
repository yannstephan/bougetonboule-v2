require "test_helper"

# Les mécaniques de saison qui tournent en tâche de fond : jauge de meute, streak hebdo,
# monstre affamé et clôture de la partie.
class SeasonJobsTest < ActiveSupport::TestCase
  setup do
    @game = create_game
    @exo, @red = @game.teams.to_a
  end

  test "la meute monte quand assez de coéquipiers ont couru" do
    week = Date.current.beginning_of_week - 7
    GameRules::PACK_RUNNERS_NEEDED.times do |i|
      m = create_player(@game, @exo, firstname: "Coureur#{i}")
      create_training(m, km: GameRules::PACK_WEEKLY_KM, date: week + 1.day)
    end

    PackLevelJob.perform_now
    assert_equal 1, @exo.reload.pack_level
    assert_in_delta 1.1, @exo.combat_multiplier, 0.001
    assert_equal 0, @red.reload.pack_level
  end

  test "sans assez de coureurs, la meute ne bouge pas" do
    m = create_player(@game, @exo)
    create_training(m, km: 20, date: Date.current.beginning_of_week - 6)

    PackLevelJob.perform_now
    assert_equal 0, @exo.reload.pack_level
  end

  test "une semaine courue fait grandir la série et paie des diamants" do
    m = create_player(@game, @exo)
    week = Date.current.beginning_of_week - 7
    create_training(m, km: 5, date: week + 2.days)

    WeeklyStreakJob.perform_now
    assert_equal 1, m.reload.weekly_streak
    assert_equal GameRules::STREAK_LADDER.first, m.user.reload.diamonds

    # Rejouer le job ne paie pas deux fois.
    WeeklyStreakJob.perform_now
    assert_equal 1, m.reload.weekly_streak
    assert_equal GameRules::STREAK_LADDER.first, m.user.reload.diamonds
  end

  test "une semaine ratée consomme un joker, puis remet la série à zéro" do
    m = create_player(@game, @exo)
    m.update!(weekly_streak: 4, streak_jokers: 1)

    WeeklyStreakJob.perform_now
    assert_equal 4, m.reload.weekly_streak
    assert_equal 0, m.streak_jokers

    m.update!(last_streak_week: nil)
    WeeklyStreakJob.perform_now
    assert_equal 0, m.reload.weekly_streak
  end

  test "le monstre affamé perd des PV sans descendre sous le plancher" do
    create_player(@game, @exo)
    @exo.monster.update!(hp: 4_000)

    FamineJob.perform_now
    assert_equal 4_000 - GameRules::FAMINE_HP_PER_DAY, @exo.monster.reload.hp

    @exo.monster.update!(hp: (GameRules::MONSTER_MAX_HP * GameRules::FAMINE_FLOOR_RATIO).round)
    assert_no_difference -> { @exo.monster.reload.hp } do
      FamineJob.perform_now
    end
  end

  test "une équipe qui court récemment ne souffre pas de la famine" do
    m = create_player(@game, @exo)
    create_training(m, km: 5, date: 1.hour.ago)

    assert_no_difference -> { @exo.monster.reload.hp } do
      FamineJob.perform_now
    end
  end

  test "à la date de fin, l'équipe au plus haut pourcentage de PV gagne" do
    create_player(@game, @exo)
    @red.monster.update!(hp: 3_000)
    @game.update!(ends_at: 1.hour.ago)

    FamineJob.perform_now

    @game.reload
    assert_equal "finished", @game.status
    assert_equal @exo.id, @game.winner_team_id
  end

  test "un monstre sous 25 % déclenche le second souffle, une seule fois" do
    create_player(@game, @exo)
    monster = @exo.monster
    monster.update!(hp: (GameRules::MONSTER_MAX_HP * 0.2).round)

    monster.refresh_state!
    assert @exo.reload.second_wind_active?
    assert_equal GameRules::SECOND_WIND_HEAL_COST, @exo.heal_cost

    first_deadline = @exo.second_wind_until
    monster.refresh_state!
    assert_equal first_deadline.to_i, @exo.reload.second_wind_until.to_i
  end
end
