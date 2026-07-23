# Applique une action de combat (attaque / soin / objet) pour une participation.
class PerformAction
  Result = Struct.new(:ok, :message, keyword_init: true)
  ATTACK_COST = 1
  HEAL_COST   = 2
  BASE_POWER  = 10

  def self.call(membership, **kwargs) = new(membership, **kwargs).call

  def initialize(membership, action_type:, item_id: nil)
    @m = membership
    @action_type = action_type.to_s
    @item_id = item_id
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
      team.monster.update!(protected_until: 3.hours.from_now)
      consume(mi, "🛡️ #{@m.user.firstname} a protégé #{team.monster.name}")
      ok("Bouclier activé (3h) !")
    when "back_wind"
      TeamEffect.create!(team:, kind: "back_wind", modifier: 1.5, expires_at: 12.hours.from_now, created_by: @m)
      consume(mi, "🌬️ Vent de dos activé pour #{team.name}")
      ok("Vent de dos activé !")
    when "trap"
      err("Le piège à loup nécessite de choisir une cible (bientôt).")
    else
      consume(mi, "#{@m.user.firstname} a utilisé #{mi.item.name}")
      ok("#{mi.item.name} utilisé !")
    end
  end

  def consume(mi, description)
    mi.update!(used: true)
    Action.create!(game: @m.game, membership: @m, item_id: mi.item_id, action_type: "use_item", description:)
  end

  def notify_team(target_team, category, title, body)
    return unless target_team
    target_team.memberships.includes(:user).find_each do |mem|
      Notification.create!(user: mem.user, game: @m.game, category:, title:, body:)
    end
  end
end
