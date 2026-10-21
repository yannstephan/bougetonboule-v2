class Notification < ApplicationRecord
  CATEGORIES = %w[streak chest message training_verified training_rejected
                  league trap effect famine game_over pack attacked crit_failed healed].freeze
  # important = poussé en Web Push + listé ; secondary = listé seulement (jamais poussé).
  IMPORTANCE = %w[important secondary].freeze
  # Poussées sur le téléphone mais JAMAIS listées : un message d'équipe se lit dans le chat,
  # pas dans la liste — la notif y serait une impasse (on la touche, rien ne se passe). Le
  # push ouvre directement le canal, et la pastille 💬 du HUD fait le reste.
  PUSH_ONLY = %w[message].freeze

  belongs_to :user
  belongs_to :game, optional: true

  validates :importance, inclusion: { in: IMPORTANCE }
  validates :category, inclusion: { in: CATEGORIES }

  # On ne pousse QUE les notifications importantes. Les secondaires (activité des autres) ne
  # remontent que dans la liste, sans notification push.
  after_create_commit :push_if_important

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :listed, -> { where.not(category: PUSH_ONLY) }

  # Crée la même notification pour plusieurs destinataires (feed d'activité, annonces).
  def self.broadcast(users, importance: "secondary", **attrs)
    Array(users).compact.uniq.each { |user| create!(user:, importance:, **attrs) }
  end

  def read? = read_at.present?
  def read! = update(read_at: Time.current)
  def important? = importance == "important"

  private

  def push_if_important
    SendWebPushJob.perform_later(id) if important?
  end
end
