class Conversation < ApplicationRecord
  KINDS = %w[general team].freeze

  belongs_to :game
  belongs_to :team, optional: true
  has_many :messages, dependent: :destroy
  has_many :conversation_reads, dependent: :destroy

  validates :kind, inclusion: { in: KINDS }

  scope :general, -> { where(kind: "general") }
  scope :team_chats, -> { where(kind: "team") }
end
