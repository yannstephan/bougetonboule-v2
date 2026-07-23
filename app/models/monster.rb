class Monster < ApplicationRecord
  STATES = %w[healthy hurt critical defeated].freeze

  belongs_to :team

  validates :name, presence: true

  def protected? = protected_until.present? && protected_until.future?
  def alive? = hp.to_i.positive?
  def hp_ratio = max_hp.to_i.zero? ? 0.0 : (hp.to_f / max_hp)
  def hp_percent = (hp_ratio * 100).round
end
