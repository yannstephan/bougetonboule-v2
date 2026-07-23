class Team < ApplicationRecord
  belongs_to :game
  belongs_to :opponent, class_name: "Team", foreign_key: "opponent_id", optional: true
  has_one  :monster, dependent: :destroy
  has_one  :conversation, dependent: :nullify
  has_many :memberships, dependent: :destroy
  has_many :team_effects, dependent: :destroy

  validates :name, presence: true

  def total_balls = memberships.sum(:balls)
  def active_effects = team_effects.active
  def active_effect(kind) = active_effects.find_by(kind:)
end
