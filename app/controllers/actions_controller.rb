class ActionsController < ApplicationController
  before_action :require_authentication

  def create
    m = current_membership
    return redirect_to root_path, alert: "Aucune partie active." unless m
    result = PerformAction.call(m, action_type: params[:action_type], item_id: params[:item_id])
    flash[result.ok ? :notice : :alert] = result.message
    redirect_to combat_path
  end
end
