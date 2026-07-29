# Applique une action de combat (attaque / soin / objet) pour une participation.
# Les coûts, durées et modificateurs vivent dans GameRules.
class PerformAction
  Result = Struct.new(:ok, :message, keyword_init: true)

  def self.call(membership, **kwargs) = new(membership, **kwargs).call

  def initialize(membership, action_type:, item_id: nil, target_id: nil, target_team: nil)
    @m = membership
    @action_type = action_type.to_s
    @item_id = item_id
    @target_id = target_id
    @target_team = target_team # "mine" / "foe" — pour les objets qui visent une équipe (fumigène)
  end

  def call
    return err("La partie est terminée") unless @m.game.active?

    case @action_type
    when "attack"   then attack
    when "heal"     then heal
    when "use_item" then use_item
    else err("Action inconnue")
    end
  end

  private

  def team = @m.team
  def power = (GameRules::BASE_POWER * team.combat_multiplier).round
  def ok(msg)  = Result.new(ok: true, message: msg)
  def err(msg) = Result.new(ok: false, message: msg)

  def attack
    return err("Pas assez de boules") if @m.balls < GameRules::ATTACK_COST
    foe = team.opponent&.monster
    return err("Aucun adversaire") unless foe
    return err("Le monstre adverse est protégé 🛡️") if foe.protected?
    return err("L'adversaire est déjà vaincu") unless foe.alive?
    return crit_fail(foe) if rand < GameRules::CRIT_FAIL_CHANCE

    dmg = power
    foe.update!(hp: [foe.hp - dmg, 0].max)
    foe.refresh_state!
    @m.update!(balls: @m.balls - GameRules::ATTACK_COST)
    Action.create!(game: @m.game, membership: @m, action_type: "attack", target: foe, amount: dmg,
                   description: "#{@m.user.firstname} a attaqué #{foe.name} (-#{dmg} PV)")
    broadcast_combat("attacked", "⚡ Attaque sur #{foe.name}",
                     self_body:   "Tu as infligé -#{dmg} PV à #{foe.name}.",
                     others_body: "#{@m.user.firstname} a infligé -#{dmg} PV à #{foe.name}.")
    unless foe.alive?
      FinishGame.call(@m.game, winner: team)
      return ok("💥 #{foe.name} est vaincu — victoire des #{team.name} !")
    end

    ok("-#{dmg} PV infligés à #{foe.name} !")
  end

  # L'attaque rate : 0 dégât, le monstre mord 15 % du solde (min 1, max 10 🍑).
  # Result ok: false uniquement pour que le flash s'affiche en rouge — les 🍑 sont bien perdues.
  def crit_fail(foe)
    loss = (@m.balls * GameRules::CRIT_FAIL_RATIO).round
               .clamp(GameRules::CRIT_FAIL_MIN, GameRules::CRIT_FAIL_MAX)
    loss = [loss, @m.balls].min
    @m.update!(balls: @m.balls - loss)
    Action.create!(game: @m.game, membership: @m, action_type: "attack", target: foe, amount: 0,
                   description: "#{@m.user.firstname} s'est fait mordre par #{foe.name} (échec critique, -#{loss} 🍑)")
    broadcast_combat("crit_failed", "💥 Échec critique !",
                     self_body:   "#{foe.name} t'a mordu le petit boule : attaque ratée, -#{loss} 🍑.",
                     others_body: "#{@m.user.firstname} s'est fait mordre le petit boule par #{foe.name} — attaque ratée, -#{loss} 🍑.")
    err("💥 Échec critique ! #{foe.name} t'a mordu le petit boule : -#{loss} 🍑 et 0 dégât.")
  end

  def heal
    cost = team.heal_cost
    return err("Pas assez de boules") if @m.balls < cost
    mine = team.monster
    return err("#{mine.name} est déjà au maximum") if mine.hp >= mine.max_hp

    amt = [power, mine.max_hp - mine.hp].min
    mine.update!(hp: mine.hp + amt)
    mine.refresh_state!
    @m.update!(balls: @m.balls - cost)
    Action.create!(game: @m.game, membership: @m, action_type: "heal", target: mine, amount: amt,
                   description: "#{@m.user.firstname} a soigné #{mine.name} (+#{amt} PV)")
    broadcast_combat("healed", "💚 Soin sur #{mine.name}",
                     self_body:   "Tu as rendu +#{amt} PV à #{mine.name}.",
                     others_body: "#{@m.user.firstname} a rendu +#{amt} PV à #{mine.name}.")
    ok("+#{amt} PV restaurés sur #{mine.name} !")
  end

  def use_item
    mi = @m.membership_items.unused.find_by(item_id: @item_id)
    return err("Objet indisponible") unless mi

    case mi.item.effect_type
    when "shield"
      until_at = GameRules::SHIELD_DURATION.from_now
      team.monster.update!(protected_until: until_at)
      consume(mi, "🛡️ #{@m.user.firstname} a protégé #{team.monster.name}")
      broadcast_effect("🛡️ #{@m.user.firstname} a activé un bouclier jusqu'à #{until_at.strftime('%H:%M')}.")
      ok("Bouclier activé (#{GameRules::SHIELD_DURATION.in_hours.round}h) !")
    when "back_wind"
      until_at = GameRules::WIND_DURATION.from_now
      TeamEffect.create!(team:, kind: "back_wind", modifier: GameRules::BACK_WIND_MODIFIER,
                         expires_at: until_at, created_by: @m)
      consume(mi, "🌬️ Vent de dos activé pour #{team.name}")
      broadcast_effect("🌬️ #{@m.user.firstname} a activé un vent de dos jusqu'à #{until_at.strftime('%H:%M')}.")
      ok("Vent de dos activé !")
    when "face_wind"
      set_face_wind(mi)
    when "smoke"
      set_smoke(mi)
    when "trap"
      set_trap(mi)
    when "wooden_leg"
      # Se protège d'un piège sur la prochaine course. Silencieux : rien n'est annoncé
      # tant que ça n'a pas déjoué un piège (résolution à l'import de la course).
      consume(mi, "🦿 #{@m.user.firstname} a chaussé une jambe de bois")
      ok("Jambe de bois prête : elle déjouera un piège sur ta prochaine course.")
    else
      consume(mi, "#{@m.user.firstname} a utilisé #{mi.item.name}")
      ok("#{mi.item.name} utilisé !")
    end
  end

  # Vent de face : −25 % sur les 🍑 de l'équipe adverse pendant 12h. Agressif et assumé :
  # les victimes sont prévenues nominativement (notification importante).
  def set_face_wind(mi)
    foe = team.opponent
    return err("Aucun adversaire") unless foe

    until_at = GameRules::WIND_DURATION.from_now
    TeamEffect.create!(team: foe, kind: "face_wind", modifier: GameRules::FACE_WIND_MODIFIER,
                       expires_at: until_at, created_by: @m)
    consume(mi, "🌪️ #{@m.user.firstname} a lancé un vent de face sur #{foe.name}")
    Notification.broadcast(foe.memberships.includes(:user).map(&:user),
                           game: @m.game, importance: "important", category: "effect",
                           title: "🌪️ Vent de face !",
                           body: "#{@m.user.firstname} souffle contre vous : −25 % de boules jusqu'à #{until_at.strftime('%H:%M')}.")
    broadcast_effect("🌪️ #{@m.user.firstname} a lancé un vent de face sur #{foe.name}.", except_team: foe)
    ok("Vent de face lancé sur #{foe.name} !")
  end

  # Fumigène : l'équipe adverse est TOUJOURS aveuglée 24h ; le poseur choisit QUEL monstre lui
  # est masqué — le sien (`mine`) ou celui de l'adversaire (`foe`, défaut).
  def set_smoke(mi)
    foe = team.opponent
    return err("Aucun adversaire à enfumer.") unless foe

    masked_team = @target_team == "mine" ? team : foe
    monster = masked_team.monster
    until_at = GameRules::SMOKE_DURATION.from_now
    TeamEffect.create!(team: foe, kind: "smoke", masked_team:, expires_at: until_at, created_by: @m)
    consume(mi, "🌫️ #{@m.user.firstname} a masqué les PV de #{monster.name} à #{foe.name}")
    Notification.broadcast(foe.memberships.includes(:user).map(&:user),
                           game: @m.game, importance: "important", category: "effect",
                           title: "🌫️ Fumigène !",
                           body: "#{@m.user.firstname} vous enfume : vous ne voyez plus les PV de #{monster.name} jusqu'à #{until_at.strftime('%H:%M')}.")
    broadcast_effect("🌫️ #{@m.user.firstname} a masqué les PV de #{monster.name} pour #{foe.name}.", except_team: foe)
    ok("Fumigène : PV de #{monster.name} masqués pour #{foe.name} !")
  end

  # Pose un piège sur un adversaire précis. La cible est enregistrée (résolution à l'import
  # de sa prochaine course), mais l'annonce publique reste générique : personne ne voit QUI est visé.
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

  # Annonce secondaire d'un effet d'équipe — feed d'activité, pas de push.
  # except_team : équipe déjà prévenue par une notification importante dédiée.
  def broadcast_effect(body, except_team: nil)
    recipients = other_players
    recipients -= except_team.memberships.includes(:user).map(&:user) if except_team
    Notification.broadcast(recipients, game: @m.game, category: "effect",
                           title: "✨ Effet d'équipe", body:)
  end

  # Attaques et soins remontent dans le fil d'activité (secondaire) avec les PV en jeu.
  # L'auteur reçoit une version à la 1re personne (« Tu as… »), les autres la 3e (« X a… »).
  def broadcast_combat(category, title, self_body:, others_body:)
    Notification.create!(user: @m.user, game: @m.game, importance: "secondary",
                         category:, title:, body: self_body)
    Notification.broadcast(other_players, game: @m.game, category:, title:, body: others_body)
  end

  def other_players
    @m.game.memberships.includes(:user).where.not(id: @m.id).map(&:user)
  end

  def consume(mi, description, target: nil)
    mi.update!(used: true)
    Action.create!(game: @m.game, membership: @m, item_id: mi.item_id,
                   action_type: "use_item", description:, target:)
  end
end
