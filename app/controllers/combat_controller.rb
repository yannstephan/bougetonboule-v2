class CombatController < ApplicationController
  before_action :require_authentication

  def show
    m = current_membership
    return redirect_to root_path, alert: "Rejoins une partie pour combattre." unless m
    render inertia: "Combat", props: props(m)
  end

  private

  def props(m)
    foe = m.team.opponent
    {
      balls: m.balls,
      multiplier: m.team.multiplier.to_f,
      my_team:  { name: m.team.name, fruit_family: m.team.fruit_family, monster: monster_json(m.team.monster) },
      foe_team: foe && { name: foe.name, fruit_family: foe.fruit_family, monster: monster_json(foe.monster) },
      items: m.owned_items.map { |i| { id: i.id, name: i.name, effect_type: i.effect_type } }
    }
  end

  def monster_json(mon)
    return nil unless mon
    { name: mon.name, slug: mon.slug, hp: mon.hp, max_hp: mon.max_hp, percent: mon.hp_percent,
      state: mon.state, protected: mon.protected? }
  end
end
