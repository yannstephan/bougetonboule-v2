namespace :league do
  desc "Affiche les classements du mois et général (GAME_ID=... pour cibler une partie)"
  task standings: :environment do
    scope = ENV["GAME_ID"] ? Game.where(id: ENV["GAME_ID"]) : Game.where(status: "active")
    scope.each do |game|
      { "MOIS" => LeagueStandings.month(game), "GÉNÉRAL" => LeagueStandings.overall(game) }
        .each do |title, standings|
          puts "\n#{game.name} — #{title} (#{standings.from} → #{standings.to})"
          standings.rows.each do |row|
            puts format("  %2d. %-12s %6.1f 🍑  %6.1f km  (%d sorties)",
                        row.rank, row.membership.display_name, row.score,
                        row.distance_meters / 1000.0, row.trainings_count)
          end
        end
    end
  end

  desc "Décerne la récompense du mois à la main (MONTH=2026-06, défaut : mois dernier)"
  task award_month: :environment do
    month = ENV["MONTH"] ? Date.parse("#{ENV['MONTH']}-01") : Date.current.prev_month
    Game.where(status: "active").find_each do |game|
      result = AwardMonthlyLeague.call(game, month)
      if result.awarded
        r = result.reward
        prize = r.cosmetic ? "#{r.cosmetic.emoji} #{r.cosmetic.name}" : "#{r.amount} 💎"
        puts "#{game.name} — #{r.membership.display_name} remporte #{prize} (#{r.period})"
      else
        puts "#{game.name} — rien à décerner : #{result.reason}"
      end
    end
  end
end
