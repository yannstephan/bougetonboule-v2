# Rattrapage ponctuel : avant la règle « le loup vole les 🍑, pas les km », une course piégée
# était enregistrée avec un score à 0 et ne comptait ni en ligue ni pour la meute. On lui
# rend son score (même calcul que TrainingScorer, qui la juge à sa date réelle) — sans
# verser la moindre boule : `credit_balls!` ignore les piégées.
# Idempotent : une course déjà rescorée retombe sur le même résultat.
namespace :trapped do
  desc "Rend leur score (ligue, meute) aux courses piégées avant le correctif — aucune 🍑 versée"
  task rescore: :environment do
    Training.where(status: "trapped").order(:date).find_each do |t|
      before = t.score.to_i
      TrainingScorer.call(t)
      t.save! if t.changed?
      puts format("#%-6d %-20s %5.1f km  score %d → %d", t.id, t.membership.display_name,
                  t.distance_km, before, t.score.to_i)
    end
  end
end
