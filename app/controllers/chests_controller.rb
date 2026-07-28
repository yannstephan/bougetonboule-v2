class ChestsController < ApplicationController
  before_action :require_authentication

  def open
    chest = current_membership&.chests&.find_by(id: params[:id])
    return redirect_to root_path, alert: "Ce coffre n'existe pas." unless chest

    gains = chest.open!
    if gains
      flash[:chest] = { rarity: chest.rarity, gains: }
      redirect_to root_path
    else
      redirect_to root_path, alert: "Ce coffre est déjà ouvert."
    end
  end
end
