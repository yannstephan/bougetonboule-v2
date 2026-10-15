# Retirer une pièce du jeu APRÈS l'avoir sortie de LoadCatalog.
#
# ⚠️ `catalog:load` ne supprime jamais rien : il n'upsert que les pièces du fichier. Une pièce
# retirée du catalogue reste donc en base, en vente, et continue de tomber des coffres.
#
# Et la supprimer n'est pas anodin : `chests.cosmetic_id` et `rewards.cosmetic_id` portent des
# clés étrangères (contenu d'un coffre décidé AU DROP, cadeau de palier en attente), et seul
# `user_cosmetics` est en `dependent: :destroy`. Une pièce déjà tirée ne PEUT pas être détruite
# sans casser un coffre scellé ou un palier non réclamé — `ClaimReward` lève sur un cosmétique
# nul (`UserCosmetic.create!(cosmetic: nil)`).
#
# D'où la règle de cette tâche : on FERME la fenêtre (elle quitte la boutique et les tirages,
# mais reste acquise à ceux qui l'ont et encaissable par ceux qui l'attendent), et on ne
# supprime la ligne que si elle n'est référencée nulle part.
#
#   NAMES='Bougie de veillée,Collier de gousses d'\''ail' bin/rails catalog:retire
#
namespace :catalog do
  desc "Retire des pièces du jeu (ferme leur fenêtre, supprime si jamais tirées) : NAMES='A,B'"
  task retire: :environment do
    names = ENV["NAMES"].to_s.split(",").map(&:strip).reject(&:empty?)
    abort "NAMES='Pièce A,Pièce B' requis." if names.empty?

    names.each do |name|
      piece = Cosmetic.find_by(name: name)
      next puts "— #{name} : absente de la base, rien à faire." if piece.nil?

      owners  = piece.user_cosmetics.count
      chests  = Chest.where(cosmetic_id: piece.id).count
      rewards = Reward.where(cosmetic_id: piece.id).count

      if owners.zero? && chests.zero? && rewards.zero?
        piece.destroy!
        puts "✔ #{name} : supprimée (jamais achetée ni tirée)."
      else
        # Une fenêtre entièrement dans le passé : `Cosmetic.available` l'exclut, donc elle
        # quitte la boutique ET les tirages. Rien d'autre ne la regarde — l'armoire ignore la
        # fenêtre, et `ClaimReward` aussi : un palier en attente reste encaissable.
        piece.update!(available_from: 1.year.ago.beginning_of_day,
                      available_until: 1.day.ago.end_of_day)
        puts "✔ #{name} : retirée de la vente et des tirages (ligne conservée — " \
             "#{owners} propriétaire(s), #{chests} coffre(s), #{rewards} récompense(s))."
      end
    end
  end
end
