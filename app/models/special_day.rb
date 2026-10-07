class SpecialDay < ApplicationRecord
  belongs_to :game
  has_many :trainings, dependent: :nullify

  validates :name, :date, presence: true
end
