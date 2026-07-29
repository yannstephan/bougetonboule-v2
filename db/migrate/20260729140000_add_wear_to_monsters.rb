class AddWearToMonsters < ActiveRecord::Migration[8.1]
  # Usure du monstre : nombre de paliers de PV (75 / 50 / 25 %) franchis pour la PREMIÈRE fois.
  # Cliquet : ne redescend jamais, un monstre soigné garde ses cicatrices (voir Monster#wear_for).
  def change
    add_column :monsters, :wear, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        # Rattrapage des monstres existants : au moins l'usure correspondant à leurs PV actuels.
        execute <<~SQL.squish
          UPDATE monsters SET wear = CASE
            WHEN max_hp <= 0            THEN 0
            WHEN hp * 100 <= max_hp * 25 THEN 3
            WHEN hp * 100 <= max_hp * 50 THEN 2
            WHEN hp * 100 <= max_hp * 75 THEN 1
            ELSE 0 END
        SQL
      end
    end
  end
end
