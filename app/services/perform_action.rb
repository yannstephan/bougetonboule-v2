# Applique une action de combat (attaque / soin / objet) pour une participation.
class PerformAction
  Result = Struct.new(:ok, :message, keyword_init: true)
  ATTACK_COST = 1
  HEAL_COST   = 2
  BASE_POWER  = 10

  def self.call(membership, **kwargs) = new(membership, **kwargs).call

  def initialize(membership, action_type:, item_id: nil, target_id: nil)
    @m = membership
    @action_type = action_type.to_s
    @item_id = item_id
    @target_id = target_id
  end

  def call
    case @action_type
    when "attack"   then attack
    when "heal"     then heal
    when "use_item" then use_item
    else err("Action inconnue")
    end
  end

  private

  def team = @m.team
  def power = (BASE_POWER * team.multiplier).round
  def ok(msg)  = Result.new(ok: true, message: msg)
  def err(msg) = Result.new(ok: false, message: msg)

  def attack
    return err("Pas assez de pêches") if @m.balls < ATTACK_COST
    foe = team.opponent&.monster
    return err("Aucun adversaire") unless foe
    return err("Le monstre adverse est protégé 🛡️") if foe.protected?
    return err("L'adversaire est déjà vaincu") unless foe.alive?

    dmg = power
    foe.update!(hp: [foe.hp - dmg, 0].max)
    foe.refresh_state!
    @m.update!(balls: @m.balls - ATTACK_COST)
    Action.create!(game: @m.game, membership: @m, action_type: "attack", target: foe, amount: dmg,
                   description: "#{@m.user.firstname} a attaqué #{foe.name} (-#{dmg} PV)")
    notify_team(team.opponent, "attacked", "Ton monstre est attaqué !",
                "#{@m.user.firstname} a infligé -#{dmg} PV à #{foe.name}.")
    ok("-#{dmg} PV infligés à #{foe.name} !")
  end

  def heal
    return err("Pas assez de pêches") if @m.balls < HEAL_COST
    mine = team.monster
    return err("#{mine.name} est déjà au maximum") if mine.hp >= mine.max_hp

    amt = [power, mine.max_hp - mine.hp].min
    mine.update!(hp: mine.hp + amt)
    mine.refresh_state!
    @m.update!(balls: @m.balls - HEAL_COST)
    Action.create!(game: @m.game, membership: @m, action_type: "heal", target: mine, amount: amt,
                   description: "#{@m.user.firstname} a soigné #{mine.name} (+#{amt} PV)")
    ok("+#{amt} PV restaurés sur #{mine.name} !")
  end

  def use_item
    mi = @m.membership_items.unused.find_by(item_id: @item_id)
    return err("Objet indisponible") unless mi

    case mi.item.effect_type
    when "shield"
      until_at = 3.hours.from_now
      team.monster.update!(protected_until: until_at)
      consume(mi, "🛡️ #{@m.user.firstname} a protégé #{team.monster.name}")
      broadcast_effect("🛡️ #{@m.user.firstname} a activé un bouclier jusqu'à #{until_at.strftime('%H:%M')}.")
      ok("Bouclier activé (3h) !")
    when "back_wind"
      until_at = 12.hours.from_now
      TeamEffect.create!(team:, kind: "back_wind", modifier: 1.5, expires_at: until_at, created_by: @m)
      consume(mi, "🌬️ Vent de dos activé pour #{team.name}")
      broadcast_effect("🌬️ #{@m.user.firstname} a activé un vent de dos jusqu'à #{until_at.strftime('%H:%M')}.")
      ok("Vent de dos activé !")
    when "trap"
      set_trap(mi)
    when "wooden_leg"
      # Se protège d'un piège sur la prochaine course. Silencieux : rien n'est annoncé
      # tant que ça n'a pas déjoué un piège (résolution à la course, à venir).
      consume(mi, "🦿 #{@m.user.firstname} a chaussé une jambe de bois")
      ok("Jambe de bois prête : elle déjouera un piège sur ta prochaine course.")
    else
      consume(mi, "#{@m.user.firstname} a utilisé #{mi.item.name}")
      ok("#{mi.item.name} utilisé !")
    end
  end

  # Pose un piège sur un adversaire précis. La cible est enregistrée (résolution à la course,
  # à venir), mais l'annonce publique reste générique : personne ne voit QUI est visé.
  def set_trap(mi)
    target = team.opponent&.memberships&.includes(:user)&.find_by(id: @target_id)
    return err("Choisis un adversaire à piéger.") unless target

    consume(mi, "🐺 #{@m.user.firstname} a posé un piège à loup", target:)
    announce_trap
    ok("Piège à loup posé sur #{target.display_name} !")
  end

  # "Charlotte a posé un piège à loup" — vu par tous les autres joueurs, sans la cible.
  # Secondaire : ça ne concerne personne directement (la cible est cachée), pas de push.
  def announce_trap
    Notification.broadcast(other_players, game: @m.game, category: "trap",
                           title: "🐺 Piège à loup",
                           body: "#{@m.user.firstname} a posé un piège à loup.")
  end

  # Annonce secondaire d'un effet d'équipe (vent de dos, bouclier) — feed d'activité, pas de push.
  def broadcast_effect(body)
    Notification.broadcast(other_players, game: @m.game, category: "effect",
                           title: "✨ Effet d'équipe", body:)
  end

  def other_players
    @m.game.memberships.includes(:user).where.not(id: @m.id).map(&:user)
  end

  def consume(mi, description, target: nil)
    mi.update!(used: true)
    Action.create!(game: @m.game, membership: @m, item_id: mi.item_id,
                   action_type: "use_item", description:, target:)
  end

  # Combat : quand un monstre est attaqué, l'équipe visée est prévenue. Secondaire (pas de push).
  def notify_team(target_team, category, title, body)
    return unless target_team

    Notification.broadcast(target_team.memberships.includes(:user).map(&:user),
                           game: @m.game, category:, title:, body:)
  end
end
