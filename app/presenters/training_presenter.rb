# Sérialise une course pour le front : un résumé (liste des sorties d'un profil) et un détail
# complet (page d'une sortie). Un seul endroit pour formater dates, durées et allure.
class TrainingPresenter
  def initialize(training)
    @t = training
  end

  def summary
    {
      id: @t.id,
      title: @t.title.presence || "Sortie",
      date: @t.date.strftime("%d/%m/%Y"),
      time: @t.date.strftime("%H:%M"),
      day_label: day_label,
      km: @t.distance_km.round(2),
      balls: @t.score.to_f.round(1),
      status: @t.status,
      duration: duration,
      has_route: @t.has_route?,
      has_photo: @t.has_photo?
    }
  end

  def detail
    summary.merge(
      description: @t.description,
      pace: pace,
      elevation: @t.elevation_gain&.to_f,
      elapsed: format_duration(@t.elapsed_time),
      route_points: @t.route_points || [],
      photo_url: @t.photo_url,
      special_day: @t.special_day && { name: @t.special_day.name, multiplier: @t.special_day.multiplier.to_f },
      effects: effects_breakdown
    )
  end

  private

  # Ce qui a influencé les 🍑 de cette course : piège à loup (subi ou déjoué), jour spécial,
  # vents de dos/face actifs à l'heure de la sortie. Vide si la course a couru « normalement ».
  def effects_breakdown
    items = []

    case @t.status
    when "trapped"
      items << { emoji: "🐺", label: "Course piégée", tone: "bad",
                 detail: "Ta course du #{when_label} est tombée dans un piège à loup : 0 🍑." }
    when "protected"
      items << { emoji: "🦿", label: "Piège déjoué", tone: "good",
                 detail: "Un piège à loup visait ta course du #{when_label} — ta jambe de bois l'a déjoué, pêches sauvées." }
    end

    if @t.special_day
      items << { emoji: "🎉", label: "#{@t.special_day.name} · ×#{fmt(@t.special_day.multiplier)}", tone: "up",
                 detail: "Jour spécial : pêches (et plafond) doublés." }
    end

    wind_effects.each do |e|
      items << if e.kind == "back_wind"
        { emoji: "🌬️", label: "Vent de dos · ×#{fmt(e.modifier)}", tone: "up",
          detail: "Un vent de dos de ton équipe a boosté les pêches de cette course." }
      else
        { emoji: "🌪️", label: "Vent de face · ×#{fmt(e.modifier)}", tone: "down",
          detail: "Un vent de face adverse a réduit les pêches de cette course." }
      end
    end

    items
  end

  # Vents actifs sur l'équipe du coureur à l'heure réelle de la course (même règle que TrainingScorer).
  def wind_effects
    @t.membership.team.team_effects
      .where(kind: %w[back_wind face_wind])
      .where("created_at <= :at AND (expires_at IS NULL OR expires_at >= :at)", at: @t.date)
      .order(:created_at)
  end

  def when_label = @t.date.strftime("%d/%m à %H:%M")

  # 1.5 → "1,5", 2.0 → "2".
  def fmt(n)
    f = n.to_f
    f == f.to_i ? f.to_i.to_s : f.to_s.tr(".", ",")
  end

  def duration = format_duration(@t.moving_time)

  # "48:30" sous une heure, sinon "1h05".
  def format_duration(seconds)
    return nil if seconds.to_i.zero?

    h = seconds / 3600
    m = (seconds % 3600) / 60
    s = seconds % 60
    h.positive? ? format("%dh%02d", h, m) : format("%d:%02d", m, s)
  end

  # Allure "5:30 /km".
  def pace
    secs = @t.pace_seconds
    return nil unless secs

    format("%d:%02d /km", secs / 60, secs % 60)
  end

  def day_label
    case @t.date.to_date
    when Date.current then "Aujourd'hui"
    when Date.yesterday then "Hier"
    else @t.date.strftime("%d/%m/%Y")
    end
  end
end
