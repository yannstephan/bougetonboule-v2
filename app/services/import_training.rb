# Fait entrer (ou remet à jour) une activité Strava dans une participation.
#
# Un seul chemin pour les trois cas : première arrivée de la course, modification sur Strava
# (titre, sport, photo ajoutée…) et réconciliation quotidienne. La course est d'abord jugée
# par TrainingPolicy :
#   - refusée → elle est enregistrée quand même, mais inerte : 0 🍑, aucun piège consommé,
#     aucun coffre, absente du feed public. Le coureur reçoit la raison en notification.
#   - acceptée → scoring, résolution des pièges, crédit des 🍑, coffre, notifications.
#   - déjà comptée et devenue non conforme → RevokeTraining reprend les 🍑 et réarme le piège.
class ImportTraining
  def self.call(membership, activity) = new(membership, activity).call

  def initialize(membership, activity)
    @m = membership
    @activity = activity
  end

  def call
    training = @m.trainings.find_or_initialize_by(strava_activity_id: @activity["id"].to_s)
    was_counted = training.persisted? && !training.rejected?
    # Ne re-notifier un refus que s'il est nouveau ou si la raison a changé : la
    # réconciliation quotidienne repasse sur les mêmes courses.
    known_reason = training.new_record? ? nil : training.rejection_reason
    assign_attributes(training)

    verdict = TrainingPolicy.call(training)
    return revoke(training, verdict) if verdict.rejected? && was_counted
    return reject(training, verdict, notify: known_reason != verdict.message) if verdict.rejected?
    # Déjà comptée et toujours conforme : on rafraîchit seulement ce que Strava a modifié
    # (titre, photo, description). Le score et les 🍑 déjà versées ne bougent pas.
    return training.tap(&:save!) if was_counted

    accept(training)
  end

  private

  def accept(training)
    training.status = "verified"
    training.rejection_reason = nil
    supersede_shorter_duplicates(training)
    TrainingScorer.call(training)
    training.save! # la course a besoin d'un id avant de résoudre les pièges
    ResolveRunEffects.call(training) # piège à loup / jambe de bois (+ notifs importantes)
    training.save! if training.changed?

    credited = training.credit_balls!.to_i
    # La semaine est sécurisée tout de suite : le palier de série se débloque en courant,
    # pas au job du lundi suivant.
    AdvanceStreak.for_training(training)
    DropChest.call(training)
    notify_runner(training, credited)
    broadcast_run(training)
    training
  end

  # Doublon montre + téléphone : la politique refuse la nouvelle course si une plus longue
  # la recouvre. Dans l'autre sens (c'est la nouvelle la plus longue), ce sont les anciennes
  # qui sortent — et le quota du jour qu'elles occupaient se libère.
  def supersede_shorter_duplicates(training)
    TrainingPolicy.overlapping(training).each do |other|
      RevokeTraining.call(other, reason: "Doublon : une autre trace de la même sortie, plus complète, l'a remplacée.")
    end
  end

  # Course refusée : conservée (le coureur doit pouvoir comprendre pourquoi), mais elle ne
  # rapporte rien et ne déclenche rien. Rien n'est annoncé aux autres joueurs.
  def reject(training, verdict, notify:)
    training.assign_attributes(status: "rejected", rejection_reason: verdict.message,
                               score: 0, base_balls: 0, special_day: nil)
    training.save!
    return training unless notify

    Notification.create!(
      user: @m.user, game: @m.game, category: "training_rejected", importance: "important",
      title: "Course non comptée", link: "/courses/#{training.id}",
      body: "#{training.distance_km.round(1)} km · #{verdict.message}"
    )
    training
  end

  def revoke(training, verdict)
    training.save! # on garde les données Strava à jour avant de la sortir du jeu
    RevokeTraining.call(training, reason: verdict.message)
  end

  # Confirmation à soi-même (secondaire : pas urgent — le cas piégé a déjà sa notif
  # importante). Sauf porte-monnaie plein : là, on pousse — des 🍑 sont perdues.
  def notify_runner(training, credited)
    lost = training.balls_credited_at ? training.score.to_i - credited : 0

    Notification.create!(
      user: @m.user, game: @m.game, category: "training_verified",
      title: lost.positive? ? "Course importée · porte-monnaie plein !" : "Course importée",
      importance: lost.positive? ? "important" : "secondary",
      link: "/courses/#{training.id}",
      body: [
        "#{training.distance_km.round(1)} km · #{pace(training)}+#{credited} boules",
        ("#{lost} 🍑 perdues (plafond #{GameRules::WALLET_CAP}) — dépense tes boules !" if lost.positive?)
      ].compact.join(" · ")
    )
  end

  # Feed d'activité : "X a couru N km", vu par les autres joueurs de la partie (secondaire).
  def broadcast_run(training)
    others = @m.game.memberships.includes(:user).where.not(id: @m.id).map(&:user)
    gain = training.status == "trapped" ? "piégée 🐺 · 0 🍑" : "+#{training.score.to_i} 🍑"
    Notification.broadcast(others, game: @m.game, category: "training_verified",
                           title: "🏃 Nouvelle course", link: "/courses/#{training.id}",
                           body: "#{@m.display_name} a couru #{training.distance_km.round(1)} km · " \
                                 "#{pace(training)}#{gain}")
  end

  def pace(training)
    secs = training.pace_seconds
    secs ? "#{format('%d:%02d', secs / 60, secs % 60)} /km · " : ""
  end

  # Champs Strava stockés sur la course : ceux qu'on affiche (titre, tracé, photo…) et ceux
  # qui servent à la juger (sport, saisie manuelle, cardio…), pour pouvoir la re-juger plus
  # tard sans retélécharger l'activité.
  def assign_attributes(training)
    training.assign_attributes(
      date:             Time.zone.parse(@activity["start_date"].to_s),
      distance_meters:  @activity["distance"].to_i,
      title:            @activity["name"],
      description:      @activity["description"],
      moving_time:      @activity["moving_time"],
      elapsed_time:     @activity["elapsed_time"],
      elevation_gain:   @activity["total_elevation_gain"],
      route_points:     Polyline.decode(@activity.dig("map", "summary_polyline")),
      photo_url:        @activity.dig("photos", "primary", "urls")&.values&.last,
      sport_type:       @activity["sport_type"].presence || @activity["type"],
      manual:           !!@activity["manual"],
      trainer:          !!@activity["trainer"],
      flagged:          !!@activity["flagged"],
      has_heartrate:    !!@activity["has_heartrate"],
      average_heartrate: @activity["average_heartrate"],
      photo_count:      @activity["total_photo_count"].to_i
    )
  end
end
