# Effets actifs d'une équipe, pour affichage public (Hub, Combat) : chacun avec son échéance
# ("actif jusqu'à…"), pour que tout le monde voie qu'une équipe a un vent de dos, un bouclier, etc.
#
# Deux sources unifiées : les TeamEffect (vent de dos/de face) et le bouclier du monstre
# (porté par monster.protected_until).
class TeamEffectsPresenter
  KINDS = {
    "back_wind"   => { emoji: "🌬️", name: "Vent de dos" },
    "face_wind"   => { emoji: "🌪️", name: "Vent de face" },
    "shield"      => { emoji: "🥣", name: "Saladier" },
    "smoke"       => { emoji: "🍦", name: "Chantilly" },
    "second_wind" => { emoji: "💨", name: "Second souffle" }
  }.freeze

  def self.call(team) = new(team).call

  def initialize(team)
    @team = team
  end

  def call
    effects = @team.active_effects.includes(created_by: :user, masked_team: :monster).map do |e|
      # Le fumigène précise QUEL monstre est masqué à cette équipe.
      label = ("#{e.masked_team&.monster&.name} masqué" if e.kind == "smoke")
      chip(e.kind, e.expires_at, e.created_by&.display_name, label)
    end
    if @team.monster&.protected?
      effects << chip("shield", @team.monster.protected_until, nil)
    end
    effects.concat(permanent_chips)
    effects
  end

  private

  # États permanents publics : la jauge de meute (paliers hebdo) et le monstre affamé.
  def permanent_chips
    chips = []
    if @team.pack_level.positive?
      chips << { kind: "pack", emoji: "🐾", name: "Meute +#{@team.pack_percent} %",
                 until: nil, remaining: nil, by: nil }
    end
    last_run = @team.last_run_at
    if @team.monster&.alive? && (last_run.nil? || last_run < GameRules::FAMINE_WARNING_AFTER.ago)
      chips << { kind: "hungry", emoji: "🍽️", name: "Monstre affamé",
                 until: nil, remaining: nil, by: nil }
    end
    chips
  end

  def chip(kind, expires_at, by, label = nil)
    meta = KINDS[kind] || { emoji: "✨", name: kind.to_s.humanize }
    {
      kind: kind,
      emoji: meta[:emoji],
      name: label || meta[:name],
      until: until_label(expires_at),
      remaining: remaining(expires_at),
      by: by
    }
  end

  # Échéance lisible, consciente du jour : "jusqu'à 10:17" (aujourd'hui), "jusqu'à demain 10:17",
  # sinon "jusqu'au 5/8 à 10:17" — pour ne pas afficher qu'une heure sur un effet de plusieurs jours.
  def until_label(at)
    return nil unless at

    time = at.strftime("%H:%M")
    case at.to_date
    when Date.current  then "jusqu'à #{time}"
    when Date.tomorrow then "jusqu'à demain #{time}"
    else "jusqu'au #{at.strftime('%-d/%-m')} à #{time}"
    end
  end

  # Temps restant, conscient des jours : "6 j 23 h", "2h15" ou "40 min". nil si expiré.
  def remaining(expires_at)
    return nil unless expires_at

    secs = (expires_at - Time.current).to_i
    return nil if secs <= 0

    d = secs / 86_400
    h = (secs % 86_400) / 3600
    m = (secs % 3600) / 60
    if d.positive? then h.positive? ? "#{d} j #{h} h" : "#{d} j"
    elsif h.positive? then "#{h}h#{format('%02d', m)}"
    else "#{m} min"
    end
  end
end
