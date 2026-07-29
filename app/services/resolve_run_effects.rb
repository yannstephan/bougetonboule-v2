# Résout les objets « à retardement » au moment où une course arrive : le piège à loup
# le plus ancien qui visait ce coureur se referme (0 🍑), sauf si une jambe de bois était
# armée — elle le déjoue et la course garde ses boules (statut "protected").
# Un piège / une jambe ne sert qu'une fois : l'action est marquée résolue.
class ResolveRunEffects
  def self.call(training) = new(training).call

  def initialize(training)
    @t = training
    @m = training.membership
  end

  def call
    trap = pending_trap
    return @t unless trap

    if (leg = armed_wooden_leg)
      foil!(trap, leg)
    else
      snap!(trap)
    end
    @t
  end

  private

  # Le piège doit avoir été posé AVANT la course (« annule la prochaine course »),
  # pas avant l'import : une course importée en retard est jugée à sa date réelle.
  def pending_trap
    Action.joins(:item)
          .where(items: { effect_type: "trap" }, resolved_at: nil, target: @m, game: @m.game)
          .where(created_at: ..@t.date).order(:created_at).first
  end

  def armed_wooden_leg
    Action.joins(:item)
          .where(items: { effect_type: "wooden_leg" }, resolved_at: nil, membership: @m)
          .where(created_at: ..@t.date).order(:created_at).first
  end

  # Piège déjoué : la course garde ses boules, la jambe de bois se révèle enfin.
  def foil!(trap, leg)
    now = Time.current
    trap.update!(resolved_at: now)
    leg.update!(resolved_at: now)
    @t.status = "protected"

    notify(@m.user, importance: "important", title: "🦿 Piège déjoué !",
           body: "Un piège à loup visait ta course de #{km} km — ta jambe de bois l'a déjoué. +#{@t.score.to_i} 🍑 sauvées !")
    notify(trap.membership.user, importance: "important", title: "😬 Piège déjoué",
           body: "#{@m.display_name} avait une jambe de bois : ton piège à loup n'a rien annulé.")
    Notification.broadcast(others_than(@m, trap.membership), game: @m.game, category: "trap",
                           title: "🦿 Jambe de bois",
                           body: "La jambe de bois de #{@m.display_name} a déjoué un piège à loup !")
  end

  # Piège refermé : 0 🍑. La victime ne voit pas qui l'a piégée (l'annonce de pose était
  # déjà anonyme côté cible) ; le piégeur, lui, est félicité nominativement.
  def snap!(trap)
    trap.update!(resolved_at: Time.current)
    @t.status = "trapped"
    @t.score = 0

    notify(@m.user, importance: "important", title: "🐺 Course piégée !",
           body: "Ta course de #{km} km est tombée dans un piège à loup : 0 🍑 cette fois. Venge-toi !")
    notify(trap.membership.user, importance: "important", title: "🎯 Piège réussi",
           body: "Ton piège à loup a annulé la course de #{@m.display_name} (#{km} km).")
  end

  def km = @t.distance_km.round(1)

  def notify(user, **kwargs)
    Notification.create!(user:, game: @m.game, category: "trap", **kwargs)
  end

  def others_than(*memberships)
    @m.game.users.where.not(memberships: { id: memberships.map(&:id) })
  end
end
