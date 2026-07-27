# Effets actifs d'une équipe, pour affichage public (Hub, Combat) : chacun avec son échéance
# ("actif jusqu'à…"), pour que tout le monde voie qu'une équipe a un vent de dos, un bouclier, etc.
#
# Deux sources unifiées : les TeamEffect (vent de dos/de face) et le bouclier du monstre
# (porté par monster.protected_until).
class TeamEffectsPresenter
  KINDS = {
    "back_wind" => { emoji: "🌬️", name: "Vent de dos" },
    "face_wind" => { emoji: "🍃", name: "Vent de face" },
    "shield"    => { emoji: "🛡️", name: "Bouclier" }
  }.freeze

  def self.call(team) = new(team).call

  def initialize(team)
    @team = team
  end

  def call
    effects = @team.active_effects.includes(created_by: :user).map do |e|
      chip(e.kind, e.expires_at, e.created_by&.display_name)
    end
    if @team.monster&.protected?
      effects << chip("shield", @team.monster.protected_until, nil)
    end
    effects
  end

  private

  def chip(kind, expires_at, by)
    meta = KINDS[kind] || { emoji: "✨", name: kind.to_s.humanize }
    {
      kind: kind,
      emoji: meta[:emoji],
      name: meta[:name],
      until: expires_at&.strftime("%H:%M"),
      remaining: remaining(expires_at),
      by: by
    }
  end

  # "2h15" ou "40 min" — nil si pas d'échéance ou déjà expiré.
  def remaining(expires_at)
    return nil unless expires_at

    secs = (expires_at - Time.current).to_i
    return nil if secs <= 0

    h = secs / 3600
    m = (secs % 3600) / 60
    h.positive? ? "#{h}h#{format('%02d', m)}" : "#{m} min"
  end
end
