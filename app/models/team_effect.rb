class TeamEffect < ApplicationRecord
  KINDS = %w[back_wind face_wind shield smoke second_wind].freeze

  belongs_to :team
  belongs_to :created_by, class_name: "Membership", foreign_key: "created_by_id", optional: true

  validates :kind, inclusion: { in: KINDS }

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

  # Les vents qui soufflaient sur l'équipe à un instant donné. On interroge la date RÉELLE
  # de la course, pas l'heure de l'import : une course importée en retard (réconciliation
  # quotidienne, webhook manqué) est jugée au moment où elle a été courue.
  scope :winds_at, lambda { |time|
    where(kind: %w[back_wind face_wind])
      .where("created_at <= :at AND (expires_at IS NULL OR expires_at >= :at)", at: time)
      .order(:created_at)
  }
end
