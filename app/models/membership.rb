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

  def owned_items = membership_items.unused.includes(:item).map(&:item)

  def display_name = user.firstname.presence || user.email.to_s.split("@").first
  def fruit_name = FruitCatalog.name_for(fruit)

  # Les deux conversations d'une participation : le chat général puis celui de son équipe
  # (ordre alphabétique des `kind` — c'est l'ordre des onglets du chat).
  def conversations
    game.conversations.general.or(game.conversations.team_chats.where(team_id:)).order(:kind)
  end

  # Nombre de messages des autres (équipe + général) postés depuis ma dernière lecture.
  # Alimente la pastille de l'onglet Chat.
  def unread_messages_count
    last_read = conversation_reads.pluck(:conversation_id, :last_read_at).to_h
    conversations.sum do |conv|
      scope = conv.messages.where.not(membership_id: id)
      # where.not(… <= dernière lecture) : strictement postérieur, sans SQL à la main.
      scope = scope.where.not(created_at: ..last_read[conv.id]) if last_read[conv.id]
      scope.count
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
