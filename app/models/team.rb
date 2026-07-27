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

  def fruits = FruitCatalog.fruits_for(fruit_family)
  def fruit_keys = FruitCatalog.keys_for(fruit_family)
end
