require "test_helper"
require "support/game_setup"

# La remise à zéro rembourse tout ce qui a été dépensé en re-jugeant les courses sans objet,
# sous les plafonds habituels. Ce test verrouille ce qui est rendu, ce qui disparaît, et que
# la simulation n'écrit rien.
class ResetCombatTest < ActiveSupport::TestCase
  include GameSetup

  setup do
    setup_game
    @trap = Item.create!(name: "Piège à loup", effect_type: "trap", price: 5)
  end

  def run!(km:, at:, status: "verified", score: nil)
    t = build_training(distance_meters: km * 1000, date: at, status:)
    TrainingScorer.call(t)
    t.score = score if score
    t.save!
    t.credit_balls!
    t
  end

  test "une course piégée retrouve ses boules, un vent de dos ne compte plus" do
    TeamEffect.create!(team: @exo, kind: "back_wind", modifier: 1.5,
                       created_at: 3.days.ago - 1.hour, expires_at: 3.days.ago + 11.hours)
    windy = run!(km: 8, at: 3.days.ago)
    assert_equal 12, windy.score.to_i
    trapped = run!(km: 6, at: 2.days.ago, status: "trapped", score: 0)
    @membership.reload.update!(balls: 1) # le reste a été dépensé

    ResetCombat.call(@game)

    assert_equal 8, windy.reload.score.to_i
    assert_equal "verified", trapped.reload.status
    assert_equal 6, trapped.score.to_i
    assert_equal 14, @membership.reload.balls
    assert_empty TeamEffect.where(team: @exo)
  end

  test "le quota du jour et le porte-monnaie gardent leurs plafonds" do
    day = 5.days.ago.change(hour: 8)
    run!(km: 7, at: day)
    split = run!(km: 7, at: day + 3.hours) # 2e moitié d'une sortie coupée en deux
    assert_equal 3, split.reload.score.to_i
    12.times { |i| run!(km: 10, at: (20 + i).days.ago) }

    ResetCombat.call(@game)

    assert_equal 3, split.reload.score.to_i
    assert_equal GameRules::WALLET_CAP, @membership.reload.balls
  end

  test "sac vidé, pièges désamorcés, monstres comme neufs" do
    MembershipItem.create!(membership: @foe, item: @trap, used: false)
    pending = Action.create!(game: @game, membership: @foe, item: @trap, action_type: "use_item", target: @membership)
    king = @exo.monster
    king.update!(hp: 2_000, wear: 3, state: "critical", protected_until: 1.hour.from_now)
    @exo.update!(second_wind_until: 2.days.from_now)

    ResetCombat.call(@game)

    assert_empty @foe.membership_items.unused
    assert pending.reload.resolved_at.present?
    king.reload
    assert_equal [ king.max_hp, 0, "healthy", nil ], [ king.hp, king.wear, king.state, king.protected_until ]
    assert_nil @exo.reload.second_wind_until
  end

  test "la simulation n'écrit rien" do
    run!(km: 8, at: 2.days.ago)
    @membership.reload.update!(balls: 0)
    @exo.monster.update!(hp: 5_000)

    rows = ResetCombat.call(@game, dry_run: true)

    assert_equal 8, rows.find { |r| r.membership == @membership }.balls_after
    assert_equal 0, @membership.reload.balls
    assert_equal 5_000, @exo.monster.reload.hp
    assert_equal 0, Notification.where(title: "🔄 Le combat repart à zéro").count
  end
end
