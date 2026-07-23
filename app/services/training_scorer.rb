# Calcule le score en pêches d'une course : 1 boule / km (plafond 10),
# multiplié si la course tombe un jour spécial de la partie.
class TrainingScorer
  MAX_BALLS_PER_RUN = 10

  def self.call(training) = new(training).call

  def initialize(training)
    @training = training
  end

  def call
    base = [@training.distance_km.floor, MAX_BALLS_PER_RUN].min
    special = matching_special_day
    @training.special_day = special
    @training.score = base * (special&.multiplier || 1)
    @training
  end

  private

  def matching_special_day
    @training.membership.game.special_days.find_by(date: @training.date.to_date)
  end
end
