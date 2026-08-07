# Une PANOPLIE : un thème, plusieurs pièces, toutes de la même rareté (validé côté
# Cosmetic). On achète toujours à la PIÈCE — la panoplie ne se vend pas en bloc. Elle sert
# à deux choses :
#   1. ranger le rayon : ses pièces sont montrées ensemble, en tête de l'onglet Cosmétiques ;
#   2. porter les PROMOTIONS — c'est le seul endroit d'où un prix peut bouger, et il se
#      pilote depuis /admin (dates + pourcentage), sans redéployer.
#
# ⚠️ Le prix promo est TOUJOURS recalculé côté serveur (`Cosmetic#current_price`) : le
# front l'affiche, il ne le décide pas. Poster un id à la main paie quand même le bon prix.
class CosmeticSet < ApplicationRecord
  has_many :cosmetics, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :promo_percent, numericality: { only_integer: true, in: 1..90 }, allow_nil: true
  validate :promo_dates_in_order

  scope :ordered, -> { order(:name) }

  # Une promo court si elle a un pourcentage ET qu'on est dans sa fenêtre. Une borne vide
  # = pas de limite de ce côté (comme les fenêtres de la boutique de saison).
  def promo?(at = Time.current)
    promo_percent.present? &&
      (promo_from.nil? || promo_from <= at) &&
      (promo_until.nil? || promo_until >= at)
  end

  # Le pourcentage EN VIGUEUR, 0 hors promo — c'est lui que le calcul de prix consomme,
  # pour qu'aucun appelant n'ait à refaire le test de la fenêtre.
  def promo_rate(at = Time.current) = promo?(at) ? promo_percent : 0

  # Jours restants avant la fin de la promo (nil si elle ne finit pas). 0 = dernier jour.
  def promo_days_left(at = Time.current)
    return nil unless promo?(at) && promo_until

    [ (promo_until.to_date - at.to_date).to_i, 0 ].max
  end

  # La rareté de la panoplie = celle de ses pièces, qui sont toutes de la même.
  def rarity = cosmetics.first&.rarity

  private

  def promo_dates_in_order
    return if promo_from.nil? || promo_until.nil? || promo_from <= promo_until

    errors.add(:promo_until, "doit venir après la date de début")
  end
end
