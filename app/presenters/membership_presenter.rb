# Carte d'identité d'un joueur (une participation) : de quoi l'afficher et cliquer vers son
# profil. Le même bloc part dans le chat, le classement, une sortie et une page profil — il
# ne se construit qu'ici, pour que « X » soit toujours dessiné et nommé pareil.
class MembershipPresenter
  def self.call(membership) = new(membership).as_json

  # Version minimale, pour un sélecteur de cible (piège à loup, fumigène).
  def self.options(memberships)
    memberships.map { |m| { id: m.id, name: m.display_name } }
  end

  def initialize(membership)
    @m = membership
  end

  def as_json(*)
    {
      id: @m.id,
      name: @m.display_name,
      avatar: AvatarPresenter.new(@m.user, membership: @m).as_json,
      team: { name: @m.team.name, color: @m.team.color }
    }
  end
end
