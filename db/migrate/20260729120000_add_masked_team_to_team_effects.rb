class AddMaskedTeamToTeamEffects < ActiveRecord::Migration[8.1]
  # Fumigène : l'équipe adverse est toujours aveuglée (colonne `team_id`), et le poseur choisit
  # QUEL monstre lui est masqué → `masked_team_id` = l'équipe dont le monstre est caché.
  def change
    add_reference :team_effects, :masked_team, foreign_key: { to_table: :teams }, null: true
  end
end
