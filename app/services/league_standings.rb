# Classement hebdomadaire d'une partie : une ligue, cinq divisions (Membership::DIVISIONS).
#
# Le score de la semaine n'est pas stocké — il est recalculé depuis les 🍑 des courses
# vérifiées de la semaine. Seule la division est persistée (Membership#division), et c'est
# LeagueWeeklyResetJob qui la fait bouger le lundi.
#
# Les zones (promotion / relégation) sont calculées ICI et nulle part ailleurs : l'écran
# Ligue et le job de clôture doivent toujours être d'accord sur qui monte et qui descend.
class LeagueStandings
  MAX_PROMOTED  = 3
  MAX_RELEGATED = 3

  Row = Struct.new(:membership, :rank, :score, :distance_meters, :trainings_count, :zone,
                   keyword_init: true)

  attr_reader :game, :week_start

  def initialize(game, week_start: Date.current.beginning_of_week)
    @game = game
    @week_start = week_start
  end

  def week_end = week_start.end_of_week

  # { 0 => [Row, …], 1 => [Row, …], … } — chaque division triée, rangs et zones renseignés.
  def by_division
    @by_division ||= begin
      grouped = rows.group_by { |row| row.membership.division }
      Membership::DIVISIONS.to_h { |d| [d[:key], ranked(grouped.fetch(d[:key], []))] }
    end
  end

  def division(key) = by_division.fetch(key, [])

  def row_for(membership)
    division(membership.division).find { |row| row.membership.id == membership.id }
  end

  # Nombre de joueurs qui montent / descendent dans une division de `size` joueurs.
  # Plafonné à un tiers de l'effectif pour que les deux zones ne se chevauchent jamais.
  def self.promoted_count(size)  = [MAX_PROMOTED, size / 3].min
  def self.relegated_count(size) = [MAX_RELEGATED, size / 3].min

  private

  def rows
    @rows ||= begin
      memberships = game.memberships.includes(:user, :team).to_a
      stats = weekly_stats(memberships)
      memberships.map do |m|
        score, meters, count = stats[m.id]
        Row.new(membership: m, score: score.to_f, distance_meters: meters.to_i,
                trainings_count: count.to_i)
      end
    end
  end

  def weekly_stats(memberships)
    Training.verified
            .where(membership_id: memberships.map(&:id))
            .where(date: week_start.beginning_of_day..week_end.end_of_day)
            .group(:membership_id)
            .pluck(:membership_id,
                   Arel.sql("SUM(score)"),
                   Arel.sql("SUM(distance_meters)"),
                   Arel.sql("COUNT(*)"))
            .to_h { |id, *values| [id, values] }
            .tap { |h| h.default = [0, 0, 0] }
  end

  def ranked(list)
    sorted = list.sort_by { |row| [-row.score, -row.distance_meters, row.membership.id] }
    promoted  = self.class.promoted_count(sorted.size)
    relegated = self.class.relegated_count(sorted.size)

    sorted.each_with_index do |row, i|
      row.rank = i + 1
      row.zone = zone_for(row, index: i, size: sorted.size, promoted:, relegated:)
    end
    sorted
  end

  def zone_for(row, index:, size:, promoted:, relegated:)
    division = row.membership.division
    # Une semaine sans courir fait descendre, quel que soit le classement.
    return "relegation" if row.score.zero? && division.positive?
    return "promotion"  if index < promoted && row.score.positive? && division < Membership::MAX_DIVISION
    return "relegation" if index >= size - relegated && division.positive?

    "safe"
  end
end
