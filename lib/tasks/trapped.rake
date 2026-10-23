# Rattrapage ponctuel : la version précédente de la règle laissait son score à une course
# piégée (et `trapped:rescore` en rendait un aux anciennes), ce qui l'ajoutait aux 🍑 du
# classement et de la fiche joueur. Une piégée vaut 0 🍑, partout : on remet son score et sa
# base à zéro. Aucune boule n'avait été versée (`credit_balls!` ignore les piégées), il n'y a
# donc rien à reprendre aux soldes. Idempotent.
namespace :trapped do
  desc "Remet à 0 🍑 les courses piégées qui avaient gardé un score"
  task reset_scores: :environment do
    Training.where(status: "trapped").where("score > 0 OR base_balls > 0").find_each do |t|
      puts format("#%-6d %-20s %5.1f km  score %d → 0", t.id, t.membership.display_name,
                  t.distance_km, t.score.to_i)
      t.update!(score: 0, base_balls: 0)
    end
  end
end
