class AddFruitsToTeamsAndMemberships < ActiveRecord::Migration[8.1]
  def change
    # La famille de fruits d'une équipe ("exotiques" / "rouges") détermine la liste
    # de fruits parmi lesquels ses joueurs choisissent leur avatar.
    add_column :teams, :fruit_family, :string

    # Le fruit-avatar du joueur, choisi une fois affecté à une équipe. Par partie :
    # un joueur peut être un fruit différent dans chaque partie.
    add_column :memberships, :fruit, :string
  end
end
