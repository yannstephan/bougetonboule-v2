class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :membership
  has_one :user, through: :membership

  validates :body, presence: true

  scope :chronological, -> { order(created_at: :asc) }
end
