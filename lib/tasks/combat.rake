# Remise à zéro du combat (ResetCombat) — après avoir rebattu les équipes en cours de saison.
# Simulation par défaut : rien n'est écrit tant qu'on ne pose pas CONFIRM=oui.
#
#   bin/rails combat:reset                 # simulation : soldes avant → après
#   CONFIRM=oui bin/rails combat:reset     # pour de vrai (+ notification à tous)
namespace :combat do
  desc "Remet le combat à zéro : PV max, effets effacés, 🍑 recalculées sans objets (CONFIRM=oui pour écrire)"
  task reset: :environment do
    dry_run = ENV["CONFIRM"] != "oui"
    scope = ENV["GAME_ID"] ? Game.where(id: ENV["GAME_ID"]) : Game.where(status: "active")

    scope.each do |game|
      rows = ResetCombat.call(game, dry_run:)
      puts "\n#{game.name}#{' — SIMULATION, rien n\'est écrit' if dry_run}"
      rows.group_by { |r| r.membership.team.name }.each do |team, team_rows|
        puts "  #{team}"
        team_rows.each do |r|
          lost = r.earned - r.balls_after
          puts format("    %-14s %4d 🍑 → %4d 🍑%s", r.membership.display_name, r.balls_before, r.balls_after,
                      (lost.positive? ? "  (#{lost} perdues au plafond)" : ""))
        end
        puts format("    %-14s %4d 🍑 → %4d 🍑", "TOTAL", team_rows.sum(&:balls_before), team_rows.sum(&:balls_after))
      end
    end
    puts "\nRelance avec CONFIRM=oui pour appliquer." if dry_run
  end
end
