class LeagueController < ApplicationController
  before_action :require_authentication
  before_action -> { require_membership("entrer au classement") }

  def show
    m = current_membership
    month   = LeagueStandings.month(m.game)
    overall = LeagueStandings.overall(m.game)

    render inertia: "Ligue", props: {
      game: { id: m.game.id, name: m.game.name },
      balls: m.balls,
      month: board_json(month, m).merge(label: HumanDates.month_label(month.from),
                                        days_left: days_left(month)),
      overall: board_json(overall, m).merge(label: "Depuis le #{overall.from.strftime('%d/%m/%Y')}"),
      last_winner: last_winner_json(m.game)
    }
  end

  private

  def board_json(standings, me)
    { rows: standings.rows.map { |row| row_json(row, me) },
      me: standings.row_for(me)&.then { |row| { rank: row.rank, score: row.score.round(1) } },
      total: standings.rows.size }
  end

  def row_json(row, me)
    MembershipPresenter.call(row.membership).merge(
      rank: row.rank, score: row.score.round(1),
      km: (row.distance_meters / 1000.0).round(1),
      trainings: row.trainings_count, me: row.membership.id == me.id
    )
  end

  def days_left(standings) = (standings.to - Date.current).to_i + 1

  # Le dernier titre décerné dans la partie, pour rappeler l'enjeu du classement mensuel.
  def last_winner_json(game)
    reward = Reward.where(source: "rank", membership: game.memberships)
                   .includes(:cosmetic, membership: :user).order(created_at: :desc).first
    return nil unless reward

    { name: reward.membership.display_name, period: reward.period,
      cosmetic: reward.cosmetic && { name: reward.cosmetic.name, emoji: reward.cosmetic.emoji },
      diamonds: reward.reward_type == "diamonds" ? reward.amount : nil }
  end
end
