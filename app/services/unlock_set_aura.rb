# L'aura d'une panoplie est sa RÉCOMPENSE. Elle ne s'achète pas (`Purchase.cosmetic` la
# refuse) et ne tombe d'aucun tirage (`Cosmetic.drawable` l'exclut du coffre, de la série et
# de la ligue) : le seul moyen de l'obtenir est de posséder toutes les AUTRES pièces de sa
# panoplie. C'est ce qui donne une raison de finir une collection.
#
# ⚠️ Appelé depuis `UserCosmetic after_create`, et pas depuis l'achat : une pièce de panoplie
# peut aussi arriver par un coffre ou un cadeau de série. Accroché à la création du lien
# joueur↔pièce, aucun chemin ne peut oublier la règle.
class UnlockSetAura
  def self.call(user_cosmetic) = new(user_cosmetic).call

  def initialize(user_cosmetic)
    @uc = user_cosmetic
  end

  # Rend l'aura débloquée, ou nil s'il n'y a rien à débloquer.
  def call
    return if set.nil? || @uc.cosmetic.aura? # une aura n'en déclenche pas une autre
    return if aura.nil? || pieces.empty?
    return unless owns_all_pieces?
    return if user.user_cosmetics.exists?(cosmetic_id: aura.id)

    granted = UserCosmetic.create!(user:, cosmetic: aura, acquired_at: Time.current,
                                   source_game: @uc.source_game)
    notify
    granted
  end

  private

  def user = @uc.user
  def set  = @uc.cosmetic.cosmetic_set
  def aura = @aura ||= set.cosmetics.find(&:aura?)
  def pieces = @pieces ||= set.cosmetics.reject(&:aura?)

  def owns_all_pieces?
    user.user_cosmetics.where(cosmetic_id: pieces.map(&:id)).distinct.count(:cosmetic_id) == pieces.size
  end

  def notify
    Notification.create!(
      user:, game: @uc.source_game, category: "streak", importance: "important",
      title: "✨ Panoplie « #{set.name} » complète !",
      body: "#{aura.name} est à toi — l'aura ne s'achète pas, elle se mérite. " \
            "Équipe-la depuis ton sac 🎒 : c'est le fond de tes écrans qui change.",
      link: "/sac?tab=wardrobe"
    )
  end
end
