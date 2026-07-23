class UserCosmetic < ApplicationRecord
  belongs_to :user
  belongs_to :cosmetic
  belongs_to :source_game, class_name: "Game", optional: true

  validates :cosmetic_id, uniqueness: { scope: :user_id }

  scope :equipped, -> { where(equipped: true) }
end
