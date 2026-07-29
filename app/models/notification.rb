class Notification < ApplicationRecord
  # Sert à choisir l'icône côté front (pages/Notifications.jsx) : toute catégorie ajoutée ici
  # doit y avoir son emoji, sinon elle retombe sur 🔔.
  CATEGORIES = %w[attacked healed crit_failed effect trap chest streak league
                  training_verified message pack famine game_over].freeze
  # important = poussé en Web Push + listé ; secondary = listé seulement (jamais poussé).
  IMPORTANCE = %w[important secondary].freeze

  belongs_to :user
  belongs_to :game, optional: true

  validates :importance, inclusion: { in: IMPORTANCE }
  validates :category, inclusion: { in: CATEGORIES }

  # On ne pousse QUE les notifications importantes. Les secondaires (activité des autres) ne
  # remontent que dans la liste, sans notification push.
  after_create_commit :push_if_important

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  # Crée la même notification pour plusieurs destinataires (feed d'activité, annonces).
  def self.broadcast(users, importance: "secondary", **attrs)
    Array(users).compact.uniq.each { |user| create!(user:, importance:, **attrs) }
  end

  def read? = read_at.present?
  def important? = importance == "important"

  private

  def push_if_important
    SendWebPushJob.perform_later(id) if important?
  end
end
