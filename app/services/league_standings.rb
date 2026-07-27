# Classements d'une partie. Deux périodes, un seul calcul :
#
#   - `month`   : du 1er au dernier jour du mois (le 1er de chaque mois, tout le monde repart à 0)
#   - `overall` : depuis le début de la partie
#
# Rien n'est stocké : le classement est recalculé depuis les 🍑 des courses vérifiées, donc il
# repart de zéro tout seul à chaque mois. Seule la récompense du vainqueur est persistée, dans
# la table `rewards` (voir LeagueMonthlyRewardJob).
class LeagueStandings
  Row = Struct.new(:membership, :rank, :score, :distance_meters, :trainings_count, keyword_init: true)

  attr_reader :game, :from, :to

  def self.month(game, date = Date.current)
    new(game, from: date.beginning_of_month, to: date.end_of_month)
  end

  def self.overall(game)
    new(game, from: (game.starts_at || game.created_at).to_date, to: Date.current)
  end

  def initialize(game, from:, to:)
    @game = game
    @from = from
    @to = to
  end

  # Toutes les participations de la partie, triées, rangs renseignés.
  def rows
    @rows ||= begin
      memberships = game.memberships.includes(:team, :user).to_a
      stats = period_stats(memberships)
      built = memberships.map do |m|
        score, meters, count = stats[m.id]
        Row.new(membership: m, score: score.to_f, distance_meters: meters.to_i,
                trainings_count: count.to_i)
      end
      rank!(built)
    end
  end

  def row_for(membership) = rows.find { |row| row.membership.id == membership.id }

  # Le 1er du classement — nil si personne n'a couru sur la période, pour ne pas
  # décerner un titre à quelqu'un qui n'a rien fait.
  def winner
    leader = rows.first
    leader if leader&.score&.positive?
  end

  private

  def period_stats(memberships)
    Training.verified
            .where(membership_id: memberships.map(&:id))
            .where(date: from.beginning_of_day..to.end_of_day)
            .group(:membership_id)
            .pluck(:membership_id,
                   Arel.sql("SUM(score)"),
                   Arel.sql("SUM(distance_meters)"),
                   Arel.sql("COUNT(*)"))
            .to_h { |id, *values| [id, values] }
            .tap { |h| h.default = [0, 0, 0] }
  end

  def rank!(list)
    sorted = list.sort_by { |row| [-row.score, -row.distance_meters, row.membership.id] }
    sorted.each_with_index { |row, i| row.rank = i + 1 }
    sorted
  end
end
