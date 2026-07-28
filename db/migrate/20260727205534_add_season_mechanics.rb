class AddSeasonMechanics < ActiveRecord::Migration[8.1]
  def change
    # Jauge de meute : paliers hebdo permanents (+10 %/palier), remplace teams.multiplier.
    add_column :teams, :pack_level, :integer, default: 0, null: false
    # Second souffle : posé une fois par partie quand le monstre passe sous 25 %.
    # Présent = déjà utilisé ; dans le futur = encore actif.
    add_column :teams, :second_wind_until, :datetime
    remove_column :teams, :multiplier, :decimal, precision: 5, scale: 2, default: "1.0", null: false

    # Pièges / jambes de bois : posés via une Action, résolus à l'import d'une course.
    add_column :actions, :resolved_at, :datetime

    # Crédit des 🍑 à l'import (idempotent, la reconciliation peut repasser).
    add_column :trainings, :balls_credited_at, :datetime

    # Fin de partie : vainqueur (mort du monstre adverse, ou plus haut % de PV à la date de fin).
    add_column :games, :winner_team_id, :integer
    add_foreign_key :games, :teams, column: :winner_team_id
  end
end
