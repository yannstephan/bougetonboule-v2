class Item < ApplicationRecord
  has_many :membership_items, dependent: :destroy

  validates :name, presence: true

  scope :not_miscellaneous, -> { where(miscellaneous: false) }
end
