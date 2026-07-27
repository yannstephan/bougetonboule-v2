class Game < ApplicationRecord
  STATUSES = %w[upcoming active finished].freeze

  belongs_to :event
  belongs_to :winner_team, class_name: "Team", optional: true
  has_many :teams, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :special_days, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :actions, dependent: :destroy
  has_many :trainings, through: :memberships

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }

  def general_conversation = conversations.find_by(kind: "general")
  def active? = status == "active"
  def finished? = status == "finished"
end
