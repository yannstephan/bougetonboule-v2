class Action < ApplicationRecord
  ACTION_TYPES = %w[attack heal use_item].freeze

  belongs_to :game
  belongs_to :membership
  belongs_to :item, optional: true
  belongs_to :target, polymorphic: true, optional: true
  # La course qui a consommé cet objet (piège refermé, jambe de bois utilisée) : si elle est
  # révoquée, l'objet est réarmé.
  belongs_to :resolved_training, class_name: "Training", optional: true

  validates :action_type, inclusion: { in: ACTION_TYPES }

  alias_method :creator, :membership

  scope :recent, -> { order(created_at: :desc) }
end
