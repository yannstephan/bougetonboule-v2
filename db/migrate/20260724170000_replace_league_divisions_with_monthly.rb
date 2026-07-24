class ReplaceLeagueDivisionsWithMonthly < ActiveRecord::Migration[8.1]
  def change
    # La ligue passe à deux classements dérivés (mensuel + général) : plus rien à persister
    # côté participation, seule la récompense du mois est enregistrée (table `rewards`).
    remove_index  :memberships, [:game_id, :division]
    remove_column :memberships, :division, :integer, default: 0, null: false
    remove_column :memberships, :last_league_rank, :integer
    remove_column :memberships, :last_league_result, :string

    # De quoi afficher un cosmétique sans assets graphiques.
    add_column :cosmetics, :emoji, :string

    # `period` ("2026-07") rend la récompense du mois idempotente : le job peut tourner
    # deux fois, ou en retard, sans jamais décerner le titre deux fois.
    add_column :rewards, :period, :string
    add_index  :rewards, [:membership_id, :source, :period], unique: true
  end
end
