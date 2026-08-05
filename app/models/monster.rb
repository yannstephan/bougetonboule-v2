class Monster < ApplicationRecord
  STATES = %w[healthy hurt critical defeated].freeze

  belongs_to :team

  validates :name, presence: true

  # Identifiant stable utilisé côté front pour choisir le dessin SVG (components/Monster.jsx).
  # Dérivé du nom : "King-Coco" → "king-coco", "Framboitrix" → "framboitrix".
  def slug = name.to_s.parameterize

  def protected? = protected_until.present? && protected_until.future?
  def alive? = hp.to_i.positive?
  def hp_ratio = max_hp.to_i.zero? ? 0.0 : (hp.to_f / max_hp)
  def hp_percent = (hp_ratio * 100).round

  # Usure visible du monstre (0 → 3) : nombre de paliers de PV franchis (75 / 50 / 25 %).
  # Le dessin s'abîme d'un cran à chaque palier (components/Monster.jsx).
  def self.wear_for(ratio) = GameRules::MONSTER_WEAR_THRESHOLDS.count { |t| ratio <= t }

  def refresh_state!
    self.state =
      if hp <= 0 then "defeated"
      elsif hp_ratio <= 0.20 then "critical"
      elsif hp_ratio <= 0.50 then "hurt"
      else "healthy"
      end
    # Cliquet : l'usure ne redescend jamais. Un palier franchi une fois laisse ses cicatrices,
    # même si l'équipe remonte les PV à bloc ensuite.
    self.wear = [ wear.to_i, self.class.wear_for(hp_ratio) ].max
    save!
    maybe_trigger_second_wind!
  end

  private

  # Second souffle : la première fois que le monstre passe sous 25 %, les soins de son
  # équipe coûtent 1 🍑 pendant 7 jours. Une seule fois par partie (second_wind_until
  # présent = déjà consommé, même expiré).
  def maybe_trigger_second_wind!
    return unless alive? && hp_ratio <= GameRules::SECOND_WIND_THRESHOLD
    return if team.second_wind_until.present?

    until_at = GameRules::SECOND_WIND_DURATION.from_now
    team.update!(second_wind_until: until_at)
    TeamEffect.create!(team:, kind: "second_wind", expires_at: until_at)
    Notification.broadcast(team.memberships.includes(:user).map(&:user),
                           game: team.game, importance: "important", category: "effect",
                           title: "💨 Second souffle !",
                           body: "#{name} est en danger : vos soins ne coûtent plus que 1 🍑 pendant 7 jours. Défendez-le !")
  end
end
