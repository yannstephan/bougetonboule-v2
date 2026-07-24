# Sérialise l'avatar d'un joueur pour le front. Un seul endroit, parce que le même
# avatar est affiché dans le Hub, le chat, le classement et l'écran de personnalisation.
class AvatarPresenter
  DEFAULT_COLOR = "peach"

  def initialize(user)
    @user = user
    @avatar = user&.avatar
  end

  def as_json(*)
    {
      color: @avatar&.base_color || DEFAULT_COLOR,
      face: @avatar&.face || Avatar::BODY_STYLES["default"],
      initial: initial,
      cosmetics: equipped_by_slot
    }
  end

  private

  def initial
    name = @user&.firstname.presence || @user&.email.to_s
    name[0]&.upcase || "?"
  end

  # { "hat" => "🎩", "aura" => "✨" } — un cosmétique équipé par slot.
  def equipped_by_slot
    return {} unless @user

    @user.user_cosmetics.equipped.includes(:cosmetic).each_with_object({}) do |uc, h|
      h[uc.cosmetic.slot] = uc.cosmetic.emoji if uc.cosmetic.emoji.present?
    end
  end
end
