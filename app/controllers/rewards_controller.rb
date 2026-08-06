# Encaissement des gains d'une semaine de série, depuis la piste du Hub.
#
# On encaisse par SEMAINE et non par gain : un palier en pose deux (les 💎 et le cadeau), et
# un bouton qui n'en prendrait qu'un laisserait l'autre en rade sans que rien ne le montre.
class RewardsController < ApplicationController
  before_action :require_authentication

  def claim_week
    m = current_membership
    return redirect_to root_path, alert: "Aucune partie active." unless m

    pending = m.rewards.pending.streak.where(streak_week: params[:week]).order(:id)
    return redirect_to root_path, alert: "Rien à réclamer sur cette semaine." if pending.empty?

    results = pending.map { |r| ClaimReward.call(m, r) }
    gains = results.select(&:ok).flat_map(&:gains)
    if gains.any?
      flash[:notice] = "Semaine #{params[:week]} encaissée : #{gains.join(' · ')}"
    else
      flash[:alert] = results.first.message
    end
    redirect_to root_path
  end
end
