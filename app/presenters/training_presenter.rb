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
      special_day: @t.special_day && { name: @t.special_day.name, multiplier: @t.special_day.multiplier.to_f }
    )
  end

  private

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
