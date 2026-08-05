# Calcule le score en boules d'une course : 1 boule / km, plafonds d'abord, multiplicateurs
# ensuite — jour spécial puis vents. Exemple : 15 km = 10 🍑 (plafond), ×1,5 avec un vent
# de dos = 15 🍑. Un jour spécial ×2 double donc aussi les plafonds effectifs (10 → 20).
#
# Deux plafonds, tous les deux sur la base (avant multiplicateurs) :
#   - par course : GameRules::MAX_BALLS_PER_RUN
#   - par jour et par participation : GameRules::MAX_BALLS_PER_DAY — couper sa sortie de
#     20 km en deux sur la montre ne rapporte rien de plus, ni en boules ni en ligue
#     (c'est le score de la course qui est tronqué).
# La base retenue est mémorisée dans `trainings.base_balls` : c'est elle qui tient le compte
# du jour, y compris quand une course est re-jugée après une modification sur Strava.
class TrainingScorer
  MAX_BALLS_PER_RUN = GameRules::MAX_BALLS_PER_RUN

  def self.call(training) = new(training).call

  def initialize(training)
    @training = training
  end

  def call
    base = [ @training.distance_km.floor, MAX_BALLS_PER_RUN, daily_room ].min.clamp(0, MAX_BALLS_PER_RUN)
    special = matching_special_day
    @training.special_day = special
    @training.base_balls = base
    @training.score = (base * (special&.multiplier || 1) * wind_factor).round
    @training
  end

  private

  # Ce qu'il reste du quota journalier de la participation, à la date réelle de la course :
  # les autres courses scorées de ce jour-là ont déjà consommé leur base.
  def daily_room
    return GameRules::MAX_BALLS_PER_DAY if @training.date.blank?

    used = @training.membership.trainings
                    .where(status: %w[verified protected])
                    .where(date: @training.date.all_day)
                    .where.not(id: @training.id)
                    .sum(:base_balls)
    GameRules::MAX_BALLS_PER_DAY - used
  end

  def matching_special_day
    @training.membership.game.special_days.find_by(date: @training.date.to_date)
  end

  # Vents actifs sur l'équipe du coureur à l'heure de la course (vent de dos ×1,5 posé par
  # l'équipe, vent de face ×0,75 posé par l'adversaire). Une course importée en retard
  # (réconciliation) est jugée à sa date réelle, pas à l'heure de l'import.
  def wind_factor
    @training.membership.team.team_effects
             .where(kind: %w[back_wind face_wind])
             .where("created_at <= :at AND (expires_at IS NULL OR expires_at >= :at)", at: @training.date)
             .reduce(1.0) { |factor, effect| factor * (effect.modifier || 1).to_f }
  end
end
