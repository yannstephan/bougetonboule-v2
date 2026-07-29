class TeamEffect < ApplicationRecord
  KINDS = %w[back_wind face_wind shield smoke second_wind].freeze

  belongs_to :team
  belongs_to :created_by, class_name: "Membership", foreign_key: "created_by_id", optional: true
  # Chantilly : l'équipe dont le monstre est masqué (aux yeux de `team`, toujours l'adversaire).
  belongs_to :masked_team, class_name: "Team", foreign_key: "masked_team_id", optional: true

  validates :kind, inclusion: { in: KINDS }

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
end
