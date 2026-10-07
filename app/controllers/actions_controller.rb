class ActionsController < ApplicationController
  before_action :require_authentication
  before_action :require_membership

  def create
    m = current_membership
    result = PerformAction.call(m, action_type: params[:action_type], item_id: params[:item_id],
                                   target_id: params[:target_id], target_team: params[:target_team])
    flash[result.ok ? :notice : :alert] = result.message
    redirect_to combat_path
  end
end
