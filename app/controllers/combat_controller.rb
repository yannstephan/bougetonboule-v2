class CombatController < ApplicationController
  before_action :require_authentication
  before_action -> { require_membership("combattre") }

  def show
    m = current_membership
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
      my_team:  team_json(m.team, viewer: m.team),
      foe_team: foe && team_json(foe, viewer: m.team),
      opponents: foe ? MembershipPresenter.options(foe.memberships.includes(:user)) : [],
      items: m.owned_items.map { |i| { id: i.id, name: i.name, effect_type: i.effect_type } }
    }
  end

  def team_json(team, viewer:)
    { name: team.name, fruit_family: team.fruit_family,
      effects: TeamEffectsPresenter.call(team),
      monster: MonsterPresenter.call(team.monster, viewer_team: viewer) }
  end
end
