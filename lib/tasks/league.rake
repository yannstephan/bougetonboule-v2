namespace :league do
  desc "Affiche le classement de la semaine en cours (GAME_ID=... pour cibler une partie)"
  task standings: :environment do
    scope = ENV["GAME_ID"] ? Game.where(id: ENV["GAME_ID"]) : Game.where(status: "active")
    scope.each do |game|
      standings = LeagueStandings.new(game)
      puts "\n#{game.name} — semaine du #{standings.week_start} au #{standings.week_end}"
      standings.by_division.each do |key, rows|
        next if rows.empty?

        puts "  #{Membership::DIVISIONS[key][:emoji]} #{Membership::DIVISIONS[key][:name]}"
        rows.each do |row|
          zone = { "promotion" => "▲", "relegation" => "▼" }.fetch(row.zone, " ")
          puts format("    %s %2d. %-12s %5.1f 🍑  %5.1f km",
                      zone, row.rank, row.membership.display_name, row.score,
                      row.distance_meters / 1000.0)
        end
      end
    end
  end

  desc "Clôture une semaine de ligue à la main (WEEK_START=2026-07-20, défaut : semaine dernière)"
  task close_week: :environment do
    week_start = ENV["WEEK_START"]
    LeagueWeeklyResetJob.perform_now(week_start)
    Membership.includes(:user).find_each do |m|
      next if m.last_league_result.blank?

      rank = m.last_league_rank == 1 ? "1er" : "#{m.last_league_rank}e"
      puts format("%-12s %-9s → %-8s (%s)", m.display_name, m.last_league_result, m.division_name, rank)
    end
  end
end
