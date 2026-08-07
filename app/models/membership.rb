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
  has_many :rewards, dependent: :destroy
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
  # Les non-lus CONVERSATION PAR CONVERSATION : c'est ce que le chat affiche sur ses onglets.
  # Un total ne dit pas OÙ il faut aller, et c'est justement ce qu'on veut savoir en arrivant.
  def unread_by_conversation
    last_read = conversation_reads.pluck(:conversation_id, :last_read_at).to_h
    conversations.to_h do |c|
      others = c.messages.where.not(membership_id: id)
      scope = last_read[c.id] ? others.where("messages.created_at > ?", last_read[c.id]) : others
      [ c.id, scope.count ]
    end
  end

  # Le total, pour la pastille du 💬 dans le bandeau (partagée sur toutes les pages).
  def unread_messages_count = unread_by_conversation.values.sum

  # « J'ouvre un canal » = ce canal-LÀ est lu jusqu'à maintenant.
  # ⚠️ Un seul, jamais les deux : marquer tout lu en ouvrant le chat effacerait la pastille
  # de l'équipe alors qu'on vient de lire la partie, et les onglets ne diraient plus rien.
  def mark_conversation_read!(conversation)
    return if conversation.nil?

    conversation_reads.find_or_initialize_by(conversation_id: conversation.id)
                      .update!(last_read_at: Time.current)
  end

  private

  # Le fruit doit appartenir à la famille de l'équipe (ou être vide tant qu'il n'a pas été choisi).
  def fruit_belongs_to_team_family
    return if fruit.blank?
    return if team&.fruit_keys&.include?(fruit)

    errors.add(:fruit, "n'est pas disponible pour cette équipe")
  end
end
