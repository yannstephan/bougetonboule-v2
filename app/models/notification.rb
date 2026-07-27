class Notification < ApplicationRecord
  CATEGORIES = %w[attacked healed streak special_day chest message training_verified game_start
                  league trap].freeze

  belongs_to :user
  belongs_to :game, optional: true

  after_create_commit { SendWebPushJob.perform_later(id) }

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def read? = read_at.present?
  def read! = update(read_at: Time.current)
end
