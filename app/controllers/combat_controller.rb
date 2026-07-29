class CombatController < ApplicationController
  before_action :require_authentication

  def show
    m = current_membership
    return redirect_to root_path, alert: "Rejoins une partie pour combattre." unless m
    return redirect_to root_path, alert: "La partie est terminée." unless m.game.active?
    render inertia: "Combat", props: props(m)
  end

  private

  def props(m)
    foe = m.team.opponent
    {
      balls: m.balls,
      multiplier: m.team.combat_multiplier.to_f,
      heal_cost: m.team.heal_cost,
      my_team:  { name: m.team.name, fruit_family: m.team.fruit_family,
                  effects: TeamEffectsPresenter.call(m.team),
                  monster: MonsterPresenter.call(m.team.monster, viewer_team: m.team) },
      foe_team: foe && { name: foe.name, fruit_family: foe.fruit_family,
                         effects: TeamEffectsPresenter.call(foe),
                         monster: MonsterPresenter.call(foe.monster, viewer_team: m.team) },
      opponents: foe ? foe.memberships.includes(:user).map { |mem| { id: mem.id, name: mem.display_name } } : [],
      items: m.owned_items.map { |i| { id: i.id, name: i.name, effect_type: i.effect_type,
                                       active: m.team.item_effect_active?(i.effect_type) } }
    }
  end

end
