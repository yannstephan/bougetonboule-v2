# Calcule le score en boules d'une course : 1 boule / km, plafond d'abord, multiplicateurs
# ensuite — jour spécial puis vents. Exemple : 15 km = 10 🍑 (plafond), ×1,5 avec un vent
# de dos = 15 🍑. Un jour spécial ×2 double donc aussi le plafond effectif (10 → 20).
class TrainingScorer
  MAX_BALLS_PER_RUN = GameRules::MAX_BALLS_PER_RUN

  def self.call(training) = new(training).call

  def initialize(training)
    @training = training
  end

  def call
    base = [@training.distance_km.floor, MAX_BALLS_PER_RUN].min
    special = matching_special_day
    @training.special_day = special
    @training.score = (base * (special&.multiplier || 1) * wind_factor).round
    @training
  end

  private

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
