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
      streak: StreakPassPresenter.call(m),
      month_rank: month_rank(m),
      bag_count: m.membership_items.unused.count,
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
      fruit_family: team.fruit_family,
      total_balls: team.total_balls,
      effects: TeamEffectsPresenter.call(team),
      monster: MonsterPresenter.call(team.monster, viewer_team: viewer),
      runs: recent_runs(team),
      tally: tally(team)
    }
  end

  # Le suivi de l'équipe : les 🍑 GAGNÉES en courant (score des courses, comme la ligue — pas
  # le solde en banque, que le combat vide) cette semaine et depuis le début, et la jauge de
  # meute de la semaine en cours, jugée par le même calcul que PackLevelJob le lundi.
  def tally(team)
    week = Date.current.beginning_of_week.beginning_of_day..Date.current.end_of_week.end_of_day
    runs = Training.scoring.where(membership_id: team.memberships.select(:id))
    since = team.game.starts_at ? runs.where(date: team.game.starts_at..) : runs
    {
      week_balls: runs.where(date: week).sum(:score).to_f.round,
      total_balls: since.sum(:score).to_f.round,
      pack: { runners: team.pack_runners(week), size: team.memberships.count,
              needed: GameRules::PACK_RUNNERS_NEEDED, km: GameRules::PACK_WEEKLY_KM,
              maxed: team.pack_level >= GameRules::PACK_MAX_LEVEL }
    }
  end

  # Les 5 dernières sorties d'une équipe, pour le fil du Hub. Les courses **refusées** en sont
  # exclues (convention du feed public : une course qui ne compte pas n'est vue que de son
  # coureur), les **piégées** y restent — elles rapportent 0 mais elles ont bien eu lieu, et
  # c'est justement ce qu'on veut voir passer.
  def recent_runs(team)
    Training.where(membership_id: team.memberships.select(:id)).real
            .includes(membership: :user)
            .recent.limit(5)
            .map do |t|
      { id: t.id, who: t.membership.display_name, km: t.distance_km.round(1),
        balls: t.balls_earned.round, trapped: t.trapped?, day: short_day(t.date) }
    end
  end

  # Date au plus court : la colonne fait une demi-largeur de téléphone.
  def short_day(at)
    case at.to_date
    when Date.current  then "Auj."
    when Date.yesterday then "Hier"
    else at.strftime("%-d/%-m")
    end
  end
end
