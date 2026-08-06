# Registre des gains. Il sert deux rôles :
#   1. garde-fou d'idempotence (index unique [membership, source, period]) — rejouer un job
#      ne paie jamais deux fois ;
#   2. file d'attente pour ce qui se RÉCLAME. `claimed_at` nil = le gain existe mais n'a pas
#      encore été encaissé ; c'est le cas des gains de série, que le joueur vient chercher sur
#      la piste du Hub. Tout le reste (coffre, ligue…) crédite à la création et naît encaissé.
class Reward < ApplicationRecord
  SOURCES = %w[streak streak_gift special_day chest rank admin].freeze
  TYPES   = %w[diamonds cosmetic balls].freeze
  # Les seules sources qui passent par la case « Réclamer ».
  CLAIMABLE_SOURCES = %w[streak streak_gift].freeze

  belongs_to :user
  belongs_to :membership, optional: true
  belongs_to :cosmetic, optional: true

  validates :source, inclusion: { in: SOURCES }
  validates :reward_type, inclusion: { in: TYPES }

  scope :pending, -> { where(claimed_at: nil) }
  scope :claimed, -> { where.not(claimed_at: nil) }
  scope :streak, -> { where(source: CLAIMABLE_SOURCES) }

  def pending? = claimed_at.nil?
end
