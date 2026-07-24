class AvatarsController < ApplicationController
  before_action :require_authentication

  def show
    render inertia: "Avatar", props: {
      avatar: AvatarPresenter.new(current_user).as_json,
      base_colors: Avatar::BASE_COLORS,
      body_styles: Avatar::BODY_STYLES.map { |key, emoji| { key:, emoji: } },
      cosmetics: owned_cosmetics,
      slots: Cosmetic::SLOTS,
      has_team: current_membership.present?
    }
  end

  def update
    avatar = current_user.avatar || current_user.build_avatar
    avatar.base_color = params[:base_color] if params[:base_color].present?
    avatar.body_style = params[:body_style] if params[:body_style].present?

    if avatar.save
      redirect_to avatar_path, notice: "Avatar mis à jour !"
    else
      redirect_to avatar_path, alert: avatar.errors.full_messages.to_sentence
    end
  end

  # Équipe (ou retire) un cosmétique possédé. Un seul par slot.
  def equip
    owned = current_user.user_cosmetics.includes(:cosmetic).find_by(cosmetic_id: params[:cosmetic_id])
    return redirect_to avatar_path, alert: "Tu ne possèdes pas ce cosmétique." unless owned

    UserCosmetic.transaction do
      same_slot = current_user.user_cosmetics.joins(:cosmetic)
                              .where(cosmetics: { slot: owned.cosmetic.slot })
      same_slot.update_all(equipped: false)
      owned.update!(equipped: params[:equipped].to_s != "false")
    end
    redirect_to avatar_path
  end

  private

  def owned_cosmetics
    current_user.user_cosmetics.includes(:cosmetic).map do |uc|
      { id: uc.cosmetic.id, name: uc.cosmetic.name, slot: uc.cosmetic.slot,
        rarity: uc.cosmetic.rarity, emoji: uc.cosmetic.emoji, equipped: uc.equipped }
    end
  end
end
