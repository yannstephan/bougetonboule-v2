# Sort une course déjà comptée du jeu : elle a été supprimée sur Strava, ou modifiée au
# point de ne plus être conforme (sport changé après coup, par exemple).
#
# On reprend les 🍑 versées (plancher à zéro, jamais de solde négatif), on remet le score à
# zéro pour que la ligue l'oublie, et surtout on **réarme le piège à loup** (ou la jambe de
# bois) que cette course avait consommé : sans ça, il suffirait de publier une vraie sortie
# pour faire claquer le piège, de la supprimer, puis de courir tranquillement.
class RevokeTraining
  def self.call(training, reason:) = new(training, reason:).call

  def initialize(training, reason:)
    @t = training
    @reason = reason
  end

  def call
    taken = @t.uncredit_balls!
    rearm_effects
    drop_sealed_chest

    @t.update!(status: "rejected", rejection_reason: @reason, score: 0, base_balls: 0,
               special_day: nil)
    notify(taken)
    @t
  end

  private

  # Le piège / la jambe de bois que cette course avait résolus redeviennent actifs.
  def rearm_effects
    Action.where(resolved_training_id: @t.id)
          .update_all(resolved_at: nil, resolved_training_id: nil)
  end

  # Un coffre encore scellé tombé sur cette course n'a plus lieu d'être (s'il est déjà
  # ouvert, les gains sont acquis — on ne reprend pas des 💎 déjà dépensés).
  def drop_sealed_chest
    chest = @t.chest
    chest.destroy if chest&.sealed?
  end

  def notify(taken)
    Notification.create!(
      user: @t.membership.user, game: @t.membership.game, category: "training_rejected",
      importance: "important", title: "Course retirée", link: "/courses/#{@t.id}",
      body: [@reason, ("#{taken} 🍑 reprises." if taken.positive?)].compact.join(" ")
    )
  end
end
