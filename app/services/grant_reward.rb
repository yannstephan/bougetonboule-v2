# Verse une récompense à une participation et la journalise dans `rewards`.
#
# Le registre est ce qui rend les cadeaux idempotents : l'index unique
# [membership, source, period] fait échouer un doublon, donc rejouer un job (streak du lundi,
# ligue du 1er du mois, ouverture d'un coffre) ne paie jamais deux fois.
#
# Trois sources l'utilisent — ligue (AwardMonthlyLeague), streak (WeeklyStreakJob) et
# coffres (Chest#open!) — pour la même mécanique : un cosmétique quand il en reste un à
# donner, des 💎 sinon.
class GrantReward
  class << self
    # Tire au sort un cosmétique que le joueur ne possède pas encore. Inventaire complet →
    # `fallback` 💎 à la place, sinon il n'y aurait rien à lui donner.
    def draw_cosmetic(membership, source:, period:, fallback:)
      cosmetic = Cosmetic.unowned_by(membership.user).order("RANDOM()").first
      return give_diamonds(membership, fallback, source:, period:) unless cosmetic

      give_cosmetic(membership, cosmetic, source:, period:)
    end

    def give_cosmetic(membership, cosmetic, source:, period:)
      UserCosmetic.create!(user: membership.user, cosmetic:, acquired_at: Time.current,
                           source_game: membership.game)
      Reward.create!(user: membership.user, membership:, cosmetic:,
                     reward_type: "cosmetic", source:, period:)
    end

    def give_diamonds(membership, amount, source:, period:)
      membership.user.increment!(:diamonds, amount)
      Reward.create!(user: membership.user, membership:, amount:,
                     reward_type: "diamonds", source:, period:)
    end

    # "👑 Couronne" ou "+100 💎" — le gain en une chips, pour les notifications.
    def label(reward)
      reward.cosmetic ? "#{reward.cosmetic.emoji} #{reward.cosmetic.name}" : "+#{reward.amount} 💎"
    end
  end
end
