class HubController < ApplicationController
  before_action :require_authentication

  def index
    scope = current_user.memberships.joins(:game)
                        .includes(game: { teams: :monster }, team: :monster)
    # Une partie active d'abord ; sinon la dernière terminée (écran de fin de saison).
    membership = scope.where(games: { status: "active" }).first ||
                 scope.where(games: { status: "finished" }).order(updated_at: :desc).first

    render inertia: "Hub", props: { membership: membership && payload(membership) }
  end

  private

  def payload(m)
    special = m.game.special_days.find_by(date: Date.current)
    {
      game: game_payload(m.game),
      event: event_payload(m.game),
      balls: m.balls,
      weekly_streak: m.weekly_streak,
      month_rank: month_rank(m),
      sealed_chests: m.chests.sealed.count,
      special_day: special && { name: special.name, multiplier: special.multiplier.to_f },
      my_team: team_payload(m.team, viewer: m.team),
      opponent: m.team.opponent && team_payload(m.team.opponent, viewer: m.team)
    }
  end

  def game_payload(game)
    {
      id: game.id, name: game.name, status: game.status,
      winner: game.winner_team&.name,
      ends_at: game.ends_at&.strftime("%d/%m/%Y")
    }
  end

  # Date de la course (jour J) + départ de la partie, pour le compte à rebours et la barre de
  # progression du Hub. `starts_at` sert de ligne de départ ; `race_at` de ligne d'arrivée.
  def event_payload(game)
    event = game.event
    return unless event&.race_date

    { name: event.name, location: event.location,
      race_at: event.race_date.iso8601, starts_at: game.starts_at&.iso8601 }
  end

  # Rang du mois, seulement si le joueur a couru — sinon on l'invite à courir.
  def month_rank(m)
    row = LeagueStandings.month(m.game).row_for(m)
    row&.rank if row&.score&.positive?
  end

  def team_payload(team, viewer:)
    {
      name: team.name,
      color: team.color,
      fruit_family: team.fruit_family,
      total_balls: team.total_balls,
      effects: TeamEffectsPresenter.call(team),
      monster: MonsterPresenter.call(team.monster, viewer_team: viewer)
    }
  end
end
