# Encaissement des gains d'une semaine de série, depuis la piste du Hub.
#
# On encaisse par SEMAINE et non par gain : un palier en pose deux (les 💎 et le cadeau), et
# un bouton qui n'en prendrait qu'un laisserait l'autre en rade sans que rien ne le montre.
class RewardsController < ApplicationController
  before_action :require_authentication
  before_action :require_membership

  def claim_week
    m = current_membership
    pending = m.rewards.pending.streak.where(streak_week: params[:week]).order(:id)
    return redirect_to root_path, alert: "Rien à réclamer sur cette semaine." if pending.empty?

    gift = pending.any? { |r| r.source == "streak_gift" }
    results = pending.map { |r| ClaimReward.call(m, r) }
    ok = results.select(&:ok)
    if ok.empty?
      flash[:alert] = results.first.message
    elsif gift
      # Le palier se RÉVÈLE comme un coffre (même modale, `ChestReveal`, montée sur le Hub) :
      # un message d'une ligne pour une pièce légendaire, c'est ce qui faisait croire que le
      # cadeau n'était jamais arrivé.
      loot = ok.flat_map(&:loot)
      flash[:chest] = { rarity: reveal_rarity(loot), gains: loot,
                        title: "Cadeau de la semaine #{params[:week]} !" }
    else
      flash[:notice] = "Semaine #{params[:week]} encaissée : #{ok.flat_map(&:gains).join(' · ')}"
    end
    redirect_to root_path
  end

  private

  # La couleur de la révélation : celle de la pièce offerte. Le repli en 💎 (inventaire
  # complet, ou doublon) se joue en rare — un palier de 5 semaines n'est pas un commun.
  def reveal_rarity(loot)
    loot.filter_map { |g| g[:rarity] }.max_by { |r| Cosmetic::RARITIES.index(r) } || "rare"
  end
end
