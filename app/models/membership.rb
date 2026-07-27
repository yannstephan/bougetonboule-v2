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
  has_many :conversation_reads, dependent: :destroy

  validates :user_id, uniqueness: { scope: :game_id }
  validates :role, inclusion: { in: ROLES }
  validate :fruit_belongs_to_team_family

  def admin? = role == "admin"
  def owned_items = membership_items.unused.includes(:item).map(&:item)

  def display_name = user.firstname.presence || user.email.to_s.split("@").first
  def fruit_name = FruitCatalog.name_for(fruit)
  def fruit_chosen? = fruit.present?

  # Les deux conversations d'une participation : le chat général + le chat de son équipe.
  def conversations
    game.conversations.where("kind = 'general' OR (kind = 'team' AND team_id = ?)", team_id)
  end

  # Nombre de messages des autres (équipe + général) postés depuis ma dernière lecture.
  # Alimente la pastille de l'onglet Chat.
  def unread_messages_count
    last_read = conversation_reads.pluck(:conversation_id, :last_read_at).to_h
    conversations.sum do |c|
      others = c.messages.where.not(membership_id: id)
      (last_read[c.id] ? others.where("messages.created_at > ?", last_read[c.id]) : others).count
    end
  end

  # « J'ouvre le chat » = tout est lu jusqu'à maintenant, dans mes deux conversations.
  def mark_conversations_read!
    now = Time.current
    conversations.each do |c|
      conversation_reads.find_or_initialize_by(conversation_id: c.id).update!(last_read_at: now)
    end
  end

  private

  # Le fruit doit appartenir à la famille de l'équipe (ou être vide tant qu'il n'a pas été choisi).
  def fruit_belongs_to_team_family
    return if fruit.blank?
    return if team&.fruit_keys&.include?(fruit)

    errors.add(:fruit, "n'est pas disponible pour cette équipe")
  end
end
