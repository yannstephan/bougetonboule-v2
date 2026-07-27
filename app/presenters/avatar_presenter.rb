# Sérialise l'avatar d'un joueur pour le front. Un seul endroit, parce que le même
# avatar est affiché dans le Hub, le chat, le classement et l'écran de personnalisation.
#
# L'avatar = un fruit (choisi par participation, donc porté par le `Membership`) sur
# lequel se posent les cosmétiques équipés (globaux, portés par le `User`). Le fruit peut
# être absent tant que le joueur n'a pas rejoint d'équipe ou pas encore choisi.
class AvatarPresenter
  def initialize(user, membership: nil)
    @user = user
    @membership = membership
  end

  def as_json(*)
    {
      fruit: @membership&.fruit,
      fruit_family: @membership&.team&.fruit_family,
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
