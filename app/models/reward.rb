class Reward < ApplicationRecord
  SOURCES = %w[streak special_day chest rank admin].freeze
  TYPES   = %w[diamonds cosmetic balls].freeze

  belongs_to :user
  belongs_to :membership, optional: true
  belongs_to :cosmetic, optional: true

  validates :source, inclusion: { in: SOURCES }
  validates :reward_type, inclusion: { in: TYPES }
end
