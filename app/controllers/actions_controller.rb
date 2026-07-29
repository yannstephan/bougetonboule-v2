class ActionsController < ApplicationController
  before_action :require_authentication
  before_action -> { require_membership("combattre") }

  def create
    result = PerformAction.call(current_membership,
                                action_type: params[:action_type], item_id: params[:item_id],
                                target_id: params[:target_id], target_team: params[:target_team])
    redirect_with result, to: combat_path
  end
end
