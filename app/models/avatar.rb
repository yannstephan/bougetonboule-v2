class Avatar < ApplicationRecord
  # Couleurs de fond : chacune correspond à un token CSS existant (--peach, --citron, …).
  BASE_COLORS = %w[peach citron fraise mint violet].freeze

  # Style de personnage. Pas d'assets graphiques : c'est l'emoji qui fait le personnage.
  BODY_STYLES = {
    "default" => "🍑", "sporty" => "🏃", "zen" => "🧘",
    "beast" => "🦖", "ghost" => "👻", "robot" => "🤖"
  }.freeze

  belongs_to :user

  validates :base_color, inclusion: { in: BASE_COLORS }
  validates :body_style, inclusion: { in: BODY_STYLES.keys }

  def face = BODY_STYLES.fetch(body_style, BODY_STYLES["default"])
end
