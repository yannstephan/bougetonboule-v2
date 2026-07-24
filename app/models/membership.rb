class Membership < ApplicationRecord
  ROLES = %w[player admin].freeze

  belongs_to :user
  belongs_to :game
  belongs_to :team
  has_many :trainings, dependent: :destroy
  has_many :actions, dependent: :destroy
  has_many :membership_items, dependent: :destroy
  has_many :items, through: :membership_items
  has_many :messages, dependent: :destroy
  has_many :chests, dependent: :destroy

  validates :user_id, uniqueness: { scope: :game_id }
  validates :role, inclusion: { in: ROLES }

  def admin? = role == "admin"
  def owned_items = membership_items.unused.includes(:item).map(&:item)

  def display_name = user.firstname.presence || user.email.to_s.split("@").first
end
