# Clôture la semaine de ligue : applique promotions et relégations, puis notifie les joueurs.
#
# Tourne le lundi (voir config/recurring.yml) et juge la semaine QUI VIENT DE SE TERMINER.
# Le classement de la nouvelle semaine repart de zéro tout seul : il est dérivé des courses
# de la semaine en cours, il n'y a donc rien à remettre à zéro en base.
class LeagueWeeklyResetJob < ApplicationJob
  queue_as :default

  def perform(week_start = nil)
    week_start = week_start ? week_start.to_date : 1.week.ago.to_date.beginning_of_week

    Game.where(status: "active").find_each do |game|
      close_week(game, week_start)
    end
  end

  private

  def close_week(game, week_start)
    standings = LeagueStandings.new(game, week_start:)
    standings.by_division.each_value do |rows|
      rows.each { |row| apply(row, standings) }
    end
  end

  def apply(row, standings)
    m = row.membership
    from = m.division
    to = (from + delta(row.zone)).clamp(0, Membership::MAX_DIVISION)
    result = to > from ? "promoted" : to < from ? "relegated" : "stayed"

    m.update!(division: to, last_league_rank: row.rank, last_league_result: result)
    notify(m, row, result, from, to, standings.week_start)
  end

  def delta(zone)
    case zone
    when "promotion"  then 1
    when "relegation" then -1
    else 0
    end
  end

  def notify(membership, row, result, from, to, week_start)
    title, body = message(row, result, from, to)
    Notification.create!(
      user: membership.user, game: membership.game, category: "league",
      title:, body:,
      payload: { result:, rank: row.rank, score: row.score,
                 from_division: from, to_division: to, week_start: week_start.to_s }
    )
  end

  def message(row, result, from, to)
    from_name = Membership::DIVISIONS[from][:name]
    to_name   = Membership::DIVISIONS[to][:name]
    peaches   = "#{row.rank == 1 ? '1er' : "#{row.rank}e"} avec #{row.score.round(1)} 🍑"

    case result
    when "promoted"
      ["🏅 Promu·e en division #{to_name} !", "#{peaches} en #{from_name} cette semaine. Bien joué !"]
    when "relegated"
      ["📉 Relégué·e en division #{to_name}", "#{peaches} en #{from_name}. Chausse les baskets, ça se rattrape."]
    else
      ["🏅 Tu restes en division #{to_name}", "#{peaches} cette semaine. Nouvelle semaine, nouveau classement !"]
    end
  end
end
