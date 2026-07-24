class AddLeagueToMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :memberships, :division, :integer, default: 0, null: false
    add_column :memberships, :last_league_rank, :integer
    add_column :memberships, :last_league_result, :string

    add_index :memberships, [:game_id, :division]
  end
end
