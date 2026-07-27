class Monster < ApplicationRecord
  STATES = %w[healthy hurt critical defeated].freeze

  belongs_to :team

  validates :name, presence: true

  # Identifiant stable utilisé côté front pour choisir le dessin SVG (components/Monster.jsx).
  # Dérivé du nom : "King-Coco" → "king-coco", "Dracassis" → "dracassis".
  def slug = name.to_s.parameterize

  def protected? = protected_until.present? && protected_until.future?
  def alive? = hp.to_i.positive?
  def hp_ratio = max_hp.to_i.zero? ? 0.0 : (hp.to_f / max_hp)
  def hp_percent = (hp_ratio * 100).round

  def refresh_state!
    self.state =
      if hp <= 0 then "defeated"
      elsif hp_ratio <= 0.20 then "critical"
      elsif hp_ratio <= 0.50 then "hurt"
      else "healthy"
      end
    save!
  end
end
