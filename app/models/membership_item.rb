class MembershipItem < ApplicationRecord
  belongs_to :membership
  belongs_to :item

  scope :unused, -> { where(used: false) }
end
