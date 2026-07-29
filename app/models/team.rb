class Team < ApplicationRecord
  belongs_to :game
  belongs_to :opponent, class_name: "Team", foreign_key: "opponent_id", optional: true
  has_one  :monster, dependent: :destroy
  has_one  :conversation, dependent: :nullify
  has_many :memberships, dependent: :destroy
  has_many :team_effects, dependent: :destroy

  validates :name, presence: true
  validates :fruit_family, inclusion: { in: FruitCatalog::FAMILY_KEYS }, allow_nil: true

  def total_balls = memberships.sum(:balls)
  def active_effects = team_effects.active
  def active_effect(kind) = active_effects.find_by(kind:)

  # Multiplicateur de combat issu de la jauge de meute : +10 % par palier, plafonné à ×2.
  # Additif et gagné uniquement en courant (jamais acheté, jamais multiplicatif).
  def combat_multiplier = [1 + pack_level * GameRules::PACK_STEP, 1 + GameRules::PACK_MAX_LEVEL * GameRules::PACK_STEP].min
  def pack_percent = (pack_level.clamp(0, GameRules::PACK_MAX_LEVEL) * GameRules::PACK_STEP * 100).round

  def second_wind_active? = second_wind_until.present? && second_wind_until.future?
  def heal_cost = second_wind_active? ? GameRules::SECOND_WIND_HEAL_COST : GameRules::HEAL_COST

  # Chantilly (kind "smoke") : un ou plusieurs pots actifs masquent, à cette équipe, les PV du/des monstre(s)
  # ciblé(s). `smoke_masks?(team_id)` = ce monstre (celui de l'équipe `team_id`) m'est-il caché ?
  def smoke_effects = active_effects.where(kind: "smoke")
  def smoke_masks?(monster_team_id) = smoke_effects.exists?(masked_team_id: monster_team_id)

  # Dernière course qui compte (pour la famine et l'avertissement du Hub).
  def last_run_at = Training.scoring.where(membership: memberships).maximum(:date)

  def fruits = FruitCatalog.fruits_for(fruit_family)
  def fruit_keys = FruitCatalog.keys_for(fruit_family)
end
