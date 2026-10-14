class UserCosmetic < ApplicationRecord
  belongs_to :user
  belongs_to :cosmetic
  belongs_to :source_game, class_name: "Game", optional: true

  validates :cosmetic_id, uniqueness: { scope: :user_id }

  scope :equipped, -> { where(equipped: true) }

  # ⚠️ Accroché ICI et pas à l'achat : une pièce de panoplie peut aussi arriver par un coffre
  # ou un cadeau de série. Sur la création du lien joueur↔pièce, aucun chemin ne peut oublier
  # de vérifier si la panoplie vient d'être complétée (voir UnlockSetAura).
  after_create :unlock_set_aura

  private

  def unlock_set_aura = UnlockSetAura.call(self)
end
