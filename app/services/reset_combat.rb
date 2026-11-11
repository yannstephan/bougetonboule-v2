# Remet le combat d'une partie à zéro, comme si personne n'avait jamais rien dépensé : à
# utiliser quand on rebat les équipes en cours de saison (sinon chacun garderait les coups
# portés et reçus avec son ancienne équipe).
#
# - Chaque course qui a eu lieu est re-jugée SANS objet : les piégées et les protégées
#   redeviennent de simples vérifiées, les vents ne comptent plus. Le barème reste celui du
#   jeu (TrainingScorer : 1 🍑/km, plafond par course et par jour, jours spéciaux).
# - Le porte-monnaie vaut la somme de ces courses, versées dans l'ordre sous le plafond
#   habituel (GameRules::WALLET_CAP) : c'est le remboursement de TOUT ce qui a été dépensé,
#   attaques, soins et objets. Les objets encore dans le sac disparaissent donc — ils sont
#   déjà rendus en 🍑.
# - Plus aucun effet : vents, chantilly, saladier, second souffle, et les pièges / jambes de
#   bois posés sont désamorcés. Monstres à leurs PV max, sans usure. Meute à zéro.
# - On ne touche à rien hors du combat : 💎, cosmétiques, séries, coffres, courses refusées.
#
# `dry_run: true` fait tout dans une transaction annulée et rend le même rapport : le
# résultat affiché est exactement celui qu'on obtiendrait.
class ResetCombat
  Row = Struct.new(:membership, :balls_before, :balls_after, :earned, keyword_init: true)

  def self.call(game, dry_run: false) = new(game, dry_run:).call

  def initialize(game, dry_run: false)
    @game = game
    @dry_run = dry_run
  end

  def call
    rows = nil
    # requires_new : la simulation annule son propre savepoint, même appelée depuis une
    # transaction déjà ouverte (sans ça, le Rollback est avalé et tout est écrit).
    ActiveRecord::Base.transaction(requires_new: true) do
      clear_effects
      rows = memberships.map { |m| rescore(m) }
      reset_monsters
      raise ActiveRecord::Rollback if @dry_run
    end
    notify unless @dry_run
    rows
  end

  private

  def memberships = @game.memberships.includes(:user, :team).order(:id).to_a
  def teams = @game.teams

  # Avant de re-juger : TrainingScorer lit les vents en base, ils doivent avoir disparu.
  # On efface aussi les vents expirés — sinon la page d'une course expliquerait encore un
  # « ×1,5 vent de dos » que son score ne contient plus.
  def clear_effects
    TeamEffect.where(team: teams).delete_all
    teams.update_all(second_wind_until: nil, pack_level: 0)
    MembershipItem.where(membership: @game.memberships, used: false).delete_all
    # Désamorcés, et détachés de leur course : si celle-ci était révoquée plus tard,
    # RevokeTraining réarmerait un piège déjà remboursé.
    Action.where(game: @game, action_type: "use_item")
          .update_all(resolved_at: Time.current, resolved_training_id: nil)
  end

  def rescore(membership)
    before = membership.balls
    # Le quota du jour se recompte de zéro : chaque course ne voit que celles d'avant.
    # Chargées APRÈS la remise à zéro : sinon une base recalculée identique à l'ancienne
    # ne serait pas « modifiée » aux yeux d'Active Record, et resterait à 0 en base.
    membership.trainings.real.update_all(status: "verified", base_balls: 0)
    runs = membership.trainings.real.order(:date, :id).to_a

    wallet = 0
    runs.each do |t|
      t.status = "verified"
      TrainingScorer.call(t)
      credited = [ t.score.to_i, GameRules::WALLET_CAP - wallet ].min.clamp(0, t.score.to_i)
      wallet += credited
      t.balls_credited_at ||= Time.current
      t.credited_balls = credited
      t.save!
    end
    membership.update!(balls: wallet)

    Row.new(membership:, balls_before: before, balls_after: wallet, earned: runs.sum { |t| t.score.to_i })
  end

  def reset_monsters
    Monster.where(team: teams).find_each do |monster|
      monster.update!(hp: monster.max_hp, wear: 0, state: "healthy", protected_until: nil)
    end
  end

  def notify
    Notification.broadcast(@game.memberships.includes(:user).map(&:user),
                           game: @game, importance: "important", category: "effect",
                           title: "🔄 Le combat repart à zéro",
                           body: "Nouvelles équipes ! Les monstres retrouvent tous leurs PV, et tes boules sont " \
                                 "recalculées : 1 🍑 par km couru depuis le début, sans les objets. " \
                                 "Tout ce que tu avais dépensé t'est rendu.")
  end
end
