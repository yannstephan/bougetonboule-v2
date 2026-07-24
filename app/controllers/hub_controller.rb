class HubController < ApplicationController
  before_action :require_authentication

  def index
    membership = current_user.memberships
                   .joins(:game).where(games: { status: "active" })
                   .includes(game: { teams: :monster }, team: :monster).first

    render inertia: "Hub", props: { membership: membership && payload(membership) }
  end

  private

  def payload(m)
    special = m.game.special_days.find_by(date: Date.current)
    {
      game: { id: m.game.id, name: m.game.name },
      balls: m.balls,
      weekly_streak: m.weekly_streak,
      month_rank: month_rank(m),
      sealed_chests: m.chests.sealed.count,
      special_day: special && { name: special.name, multiplier: special.multiplier.to_f },
      my_team: team_payload(m.team),
      opponent: m.team.opponent && team_payload(m.team.opponent)
    }
  end

  # Rang du mois, seulement si le joueur a couru — sinon on l'invite à courir.
  def month_rank(m)
    row = LeagueStandings.month(m.game).row_for(m)
    row&.rank if row&.score&.positive?
  end

  def team_payload(team)
    mon = team.monster
    {
      name: team.name,
      color: team.color,
      total_balls: team.total_balls,
      monster: mon && { name: mon.name, hp: mon.hp, max_hp: mon.max_hp,
                        percent: mon.hp_percent, state: mon.state, protected: mon.protected? }
    }
  end
end
