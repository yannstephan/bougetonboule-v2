# Enregistre une course et déroule tout ce qu'elle déclenche, dans l'ordre :
#
#   1. scoring (plafond, jour spécial, vents à la date réelle de la course) ;
#   2. résolution des objets à retardement (piège à loup / jambe de bois) ;
#   3. crédit des 🍑 au porte-monnaie, plafonné ;
#   4. coffre éventuel ;
#   5. notifications — la confirmation au coureur, le feed d'activité aux autres.
#
# C'est LE chemin d'entrée d'une course dans le jeu : le job d'import Strava comme le seed
# passent par ici, pour qu'une course seedée se comporte exactement comme une vraie.
class RecordTraining
  def self.call(training) = new(training).call

  def initialize(training)
    @t = training
    @m = training.membership
  end

  def call
    TrainingScorer.call(@t)
    ResolveRunEffects.call(@t)
    @t.save!
    credited = @t.credit_balls!.to_i # rien n'est versé si la course est piégée (score 0)
    DropChest.call(@t)
    notify_runner(credited)
    broadcast_run
    @t
  end

  private

  def link = "/courses/#{@t.id}"
  def km = @t.distance_km.round(1)

  # Confirmation à soi-même (secondaire : pas urgent — le cas piégé a déjà sa notif
  # importante). Sauf porte-monnaie plein : là, on pousse — des 🍑 sont perdues.
  def notify_runner(credited)
    lost = @t.balls_credited_at ? @t.score.to_i - credited : 0

    Notification.create!(
      user: @m.user, game: @m.game, category: "training_verified", link:,
      title: lost.positive? ? "Course importée · porte-monnaie plein !" : "Course importée",
      importance: lost.positive? ? "important" : "secondary",
      body: [
        "#{km} km · +#{credited} boules",
        ("#{lost} 🍑 perdues (plafond #{GameRules::WALLET_CAP}) — dépense tes boules !" if lost.positive?)
      ].compact.join(" · ")
    )
  end

  # Feed d'activité : "X a couru N km", vu par les autres joueurs de la partie (secondaire).
  def broadcast_run
    gain = @t.status == "trapped" ? "piégée 🐺 · 0 🍑" : "+#{@t.score.to_i} 🍑"
    Notification.broadcast(@m.game.users.where.not(memberships: { id: @m.id }),
                           game: @m.game, category: "training_verified", link:,
                           title: "🏃 Nouvelle course",
                           body: "#{@m.display_name} a couru #{km} km · #{gain}")
  end
end
