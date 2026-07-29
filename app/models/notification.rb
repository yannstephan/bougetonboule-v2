class Notification < ApplicationRecord
  CATEGORIES = %w[attacked healed streak special_day chest message training_verified
                  training_rejected game_start league trap effect].freeze
  # important = poussé en Web Push + listé ; secondary = listé seulement (jamais poussé).
  IMPORTANCE = %w[important secondary].freeze

  belongs_to :user
  belongs_to :game, optional: true

  validates :importance, inclusion: { in: IMPORTANCE }

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
  def read! = update(read_at: Time.current)
  def important? = importance == "important"

  private

  def push_if_important
    SendWebPushJob.perform_later(id) if important?
  end
end
