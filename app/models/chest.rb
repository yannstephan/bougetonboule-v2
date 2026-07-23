class Chest < ApplicationRecord
  RARITIES = %w[common rare epic legendary].freeze
  STATUSES = %w[sealed opened].freeze

  belongs_to :membership
  belongs_to :training, optional: true
  belongs_to :cosmetic, optional: true

  validates :rarity, inclusion: { in: RARITIES }

  scope :sealed, -> { where(status: "sealed") }

  def sealed? = status == "sealed"
end
