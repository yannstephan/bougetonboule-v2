class Membership < ApplicationRecord
  ROLES = %w[player admin].freeze

  # Divisions de la ligue, de la plus basse à la plus haute (index = colonne `division`).
  DIVISIONS = [
    { key: 0, name: "Bronze",  emoji: "🥉" },
    { key: 1, name: "Argent",  emoji: "🥈" },
    { key: 2, name: "Or",      emoji: "🥇" },
    { key: 3, name: "Platine", emoji: "💠" },
    { key: 4, name: "Diamant", emoji: "👑" }
  ].freeze
  MAX_DIVISION = DIVISIONS.size - 1
  LEAGUE_RESULTS = %w[promoted stayed relegated].freeze

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
  validates :division, inclusion: { in: 0..MAX_DIVISION }
  validates :last_league_result, inclusion: { in: LEAGUE_RESULTS }, allow_nil: true

  def admin? = role == "admin"
  def owned_items = membership_items.unused.includes(:item).map(&:item)

  def division_info = DIVISIONS[division]
  def division_name = division_info[:name]
  def display_name = user.firstname.presence || user.email.to_s.split("@").first
end
