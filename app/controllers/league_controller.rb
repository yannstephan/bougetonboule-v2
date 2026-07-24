class LeagueController < ApplicationController
  before_action :require_authentication

  def show
    m = current_membership
    return redirect_to root_path, alert: "Rejoins une partie pour entrer en ligue." unless m

    standings = LeagueStandings.new(m.game)
    rows = standings.division(m.division)
    render inertia: "Ligue", props: props(m, standings, rows)
  end

  private

  def props(m, standings, rows)
    {
      game: { id: m.game.id, name: m.game.name },
      balls: m.balls,
      division: m.division_info,
      divisions: Membership::DIVISIONS,
      week: week_json(standings),
      counts: { promoted: LeagueStandings.promoted_count(rows.size),
                relegated: LeagueStandings.relegated_count(rows.size) },
      rows: rows.map { |row| row_json(row, m) },
      me: standings.row_for(m)&.then { |row| { rank: row.rank, score: row.score.round(1), zone: row.zone } },
      last_week: m.last_league_result && { rank: m.last_league_rank, result: m.last_league_result }
    }
  end

  def week_json(standings)
    { starts_on: standings.week_start.strftime("%d/%m"),
      ends_on: standings.week_end.strftime("%d/%m"),
      days_left: (standings.week_end - Date.current).to_i + 1 }
  end

  def row_json(row, me)
    m = row.membership
    { id: m.id, rank: row.rank, name: m.display_name, initial: m.display_name[0].upcase,
      team: { name: m.team.name, color: m.team.color },
      score: row.score.round(1), km: (row.distance_meters / 1000.0).round(1),
      trainings: row.trainings_count, zone: row.zone, me: m.id == me.id }
  end
end
