# Juge une course importée : est-ce qu'elle compte, ou pas ? Tout est automatique
# (aucune validation humaine) — la course passe, ou elle est rejetée avec une raison
# lisible par le joueur, affichée sur sa sortie et envoyée en notification.
#
# Les seuils vivent dans GameRules. L'ordre des contrôles est celui du message qu'on
# veut voir en premier : nature de l'activité, puis effort, puis date, puis unicité.
#
# S'appuie uniquement sur les colonnes de la course (pas sur la charge utile Strava) :
# c'est ce qui permet de re-juger une course modifiée après coup, sans la re-télécharger.
class TrainingPolicy
  Verdict = Struct.new(:code, :message) do
    def ok? = code.nil?
    def rejected? = !ok?
  end

  OK = Verdict.new(nil, nil).freeze

  SPORT_LABELS = {
    "Ride" => "sortie vélo", "VirtualRide" => "vélo virtuel", "EBikeRide" => "vélo électrique",
    "Walk" => "marche", "Hike" => "randonnée", "Swim" => "natation", "Workout" => "séance",
    "Elliptical" => "elliptique", "Rowing" => "rameur", "Golf" => "golf", "Ski" => "ski"
  }.freeze

  def self.call(training) = new(training).call

  def initialize(training)
    @t = training
  end

  def call
    reason = nature || effort || window || uniqueness
    reason || OK
  end

  # Les courses déjà enregistrées que cette sortie recouvre (doublon montre + téléphone).
  # Sert à l'import : si la nouvelle est la plus longue, ce sont les autres qui sortent.
  def self.overlapping(training) = new(training).overlapping

  def overlapping = overlapping_runs

  private

  # --- 1. Nature de l'activité ------------------------------------------------

  def nature
    sport = @t.sport_type.presence

    if sport && !sport.in?(GameRules::ALLOWED_SPORT_TYPES)
      label = SPORT_LABELS[sport] || sport
      return no(:sport_type, "Ce n'est pas une course à pied (#{label}).")
    end

    if @t.manual?
      return no(:manual, "Course ajoutée à la main sur Strava : il faut une sortie enregistrée " \
                         "par une montre ou un téléphone.")
    end

    if @t.flagged?
      return no(:flagged, "Strava a signalé cette activité comme suspecte.")
    end

    proof_of_effort
  end

  # Pas de tracé GPS (tapis, sortie virtuelle) : on demande une preuve — la fréquence
  # cardiaque, ou à défaut une photo (l'écran du tapis avec les stats), que tout le monde
  # peut voir sur la page de la course. La photo peut être ajoutée après coup sur Strava :
  # la course est alors re-jugée et créditée.
  def proof_of_effort
    return if @t.has_route?

    return if @t.has_heartrate? && GameRules::HEARTRATE_RANGE.cover?(@t.average_heartrate.to_i)
    return if @t.photo_count.to_i.positive? || @t.has_photo?

    no(:no_proof, "Course sans tracé GPS (tapis ?) : ajoute ta fréquence cardiaque ou une photo " \
                  "de l'écran sur Strava, et elle comptera.")
  end

  # --- 2. Effort plausible ----------------------------------------------------

  def effort
    km = @t.distance_km

    if km < GameRules::MIN_DISTANCE_KM
      return no(:too_short, "Moins de #{GameRules::MIN_DISTANCE_KM} km : trop court pour rapporter des boules.")
    end

    if km > GameRules::MAX_DISTANCE_KM
      return no(:too_long, "Plus de #{GameRules::MAX_DISTANCE_KM} km : distance invraisemblable.")
    end

    pace = @t.pace_seconds
    return no(:no_time, "Durée manquante : impossible de calculer ton allure.") if pace.nil?

    if pace > GameRules::MAX_PACE_SECONDS
      return no(:too_slow, "Allure trop lente (#{fmt_pace(pace)}) : il faut tenir au moins " \
                           "#{fmt_mmss(GameRules::MAX_PACE_SECONDS)} au kilomètre.")
    end

    if pace < GameRules::MIN_PACE_SECONDS
      no(:too_fast, "Allure trop rapide (#{fmt_pace(pace)}) : sous " \
                    "#{fmt_mmss(GameRules::MIN_PACE_SECONDS)} au kilomètre, ce n'est plus de la course à pied.")
    end
  end

  # --- 3. Fenêtre temporelle --------------------------------------------------

  def window
    date = @t.date
    return no(:no_date, "Course sans date.") if date.blank?

    if date > Time.current + GameRules::FUTURE_TOLERANCE
      return no(:future, "Course datée dans le futur : vérifie la date de ta montre.")
    end

    if date < GameRules::IMPORT_WINDOW.ago
      return no(:too_old, "Course vieille de plus de #{GameRules::IMPORT_WINDOW.in_days.round} jours : " \
                          "elle ne peut plus entrer dans la partie.")
    end

    game = @t.membership.game
    if game.starts_at && date < game.starts_at
      return no(:before_game, "Course antérieure au début de la partie.")
    end

    if game.ends_at && date > game.ends_at
      no(:after_game, "Course postérieure à la fin de la partie.")
    end
  end

  # --- 4. Unicité -------------------------------------------------------------

  def uniqueness
    claimed_by_someone_else || overlapping_run
  end

  # La même activité Strava importée par deux joueurs différents = fichier partagé.
  # (Le même joueur, lui, peut légitimement la faire compter dans plusieurs parties.)
  def claimed_by_someone_else
    return if @t.strava_activity_id.blank?

    exists = Training.joins(:membership)
                     .where(strava_activity_id: @t.strava_activity_id)
                     .where.not(memberships: { user_id: @t.membership.user_id })
                     .where.not(id: @t.id)
                     .exists?
    return unless exists

    no(:claimed, "Cette activité a déjà été importée par un autre joueur.")
  end

  # Doublon montre + téléphone : deux sorties du même joueur qui se recouvrent dans le
  # temps. On garde celle qui dure le plus longtemps.
  def overlapping_run
    duplicate = overlapping_runs.find { |other| duration(other) >= duration(@t) }
    return unless duplicate

    no(:duplicate, "Doublon : cette sortie recouvre une autre de tes courses " \
                   "(#{duplicate.date.strftime('%H:%M')}, #{duplicate.distance_km.round(1)} km).")
  end

  def overlapping_runs
    return [] if @t.date.blank?

    finish = @t.date + duration(@t)
    @t.membership.trainings.where(status: %w[verified protected trapped])
      .where.not(id: @t.id)
      .where(date: (@t.date - 12.hours)..finish)
      .select { |other| overlaps?(other, finish) }
  end

  def overlaps?(other, finish)
    other_finish = other.date + duration(other)
    grace = GameRules::DUPLICATE_OVERLAP_GRACE
    other.date < finish - grace && @t.date < other_finish - grace
  end

  def duration(training) = [training.elapsed_time.to_i, training.moving_time.to_i, 1].max.seconds

  # --- Utilitaires ------------------------------------------------------------

  def no(code, message) = Verdict.new(code, message)

  def fmt_pace(seconds) = "#{fmt_mmss(seconds)} /km"

  def fmt_mmss(seconds) = format("%d:%02d", seconds / 60, seconds % 60)
end
