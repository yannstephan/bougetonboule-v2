require "test_helper"

class LeagueStandingsTest < ActiveSupport::TestCase
  setup do
    @game = create_game
    @exo, @red = @game.teams.to_a
    @lea = create_player(@game, @exo, firstname: "Léa")
    @max = create_player(@game, @red, firstname: "Max")
  end

  test "les deux clans sont mélangés et classés au score" do
    create_training(@lea, km: 4)
    create_training(@max, km: 9)

    rows = LeagueStandings.month(@game).rows
    assert_equal [@max.id, @lea.id], rows.map { |r| r.membership.id }
    assert_equal [1, 2], rows.map(&:rank)
    assert_equal 9, rows.first.score
  end

  test "le classement du mois ignore les courses du mois précédent" do
    create_training(@lea, km: 9, date: 2.months.ago)
    create_training(@max, km: 3)

    assert_equal 0, LeagueStandings.month(@game).row_for(@lea).score
    assert_equal @max.id, LeagueStandings.month(@game).winner.membership.id
  end

  test "le général cumule depuis le début de la partie" do
    create_training(@lea, km: 6, date: 20.days.ago)
    create_training(@lea, km: 6)

    assert_equal 12, LeagueStandings.overall(@game).row_for(@lea).score
  end

  test "personne n'a couru : pas de vainqueur" do
    assert_nil LeagueStandings.month(@game).winner
  end

  test "la récompense du mois n'est décernée qu'une fois" do
    Cosmetic.create!(name: "Couronne", slot: "hat", rarity: "legendary", emoji: "👑")
    create_training(@lea, km: 9, date: 1.month.ago)
    month = 1.month.ago.to_date

    assert AwardMonthlyLeague.call(@game, month).awarded
    assert_equal 1, @lea.user.user_cosmetics.count

    result = AwardMonthlyLeague.call(@game, month)
    assert_not result.awarded
    assert_equal 1, @lea.user.user_cosmetics.count
  end
end
