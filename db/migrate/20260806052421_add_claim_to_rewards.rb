# Les gains de série ne sont plus versés d'office : ils attendent que le joueur les encaisse
# (bouton « Réclamer » sur la piste du Hub).
#   - `claimed_at` nil = en attente. Les autres sources (coffre, ligue…) créditent toujours à
#     la création : elles naissent donc déjà encaissées, et l'existant est backfillé pour ne
#     jamais faire repayer d'anciens gains.
#   - `streak_week` place le gain sur la piste (7e semaine de série, pas semaine ISO) : le
#     `period` seul ne le dit pas, et il devient ambigu dès qu'une série repart à zéro.
class AddClaimToRewards < ActiveRecord::Migration[8.1]
  def up
    add_column :rewards, :claimed_at, :datetime
    add_column :rewards, :streak_week, :integer
    execute "UPDATE rewards SET claimed_at = created_at"
    add_index :rewards, [ :membership_id, :claimed_at ]
  end

  def down
    remove_index :rewards, [ :membership_id, :claimed_at ]
    remove_column :rewards, :streak_week
    remove_column :rewards, :claimed_at
  end
end
