class AddImportChecks < ActiveRecord::Migration[8.1]
  def change
    # Données brutes de Strava nécessaires pour juger une course (et la re-juger si elle
    # est modifiée après coup), + la raison de rejet montrée au coureur.
    change_table :trainings, bulk: true do |t|
      t.string  :sport_type
      t.boolean :manual, default: false, null: false
      t.boolean :trainer, default: false, null: false
      t.boolean :flagged, default: false, null: false
      t.boolean :has_heartrate, default: false, null: false
      t.decimal :average_heartrate, precision: 5, scale: 1
      t.integer :photo_count, default: 0, null: false
      t.string  :rejection_reason
      # Boules « de base » retenues (avant jour spécial et vents) : sert à tenir le quota
      # journalier, y compris quand une course est re-jugée.
      t.integer :base_balls, default: 0, null: false
      # Boules réellement versées (le porte-monnaie plafonné peut en tronquer une partie) :
      # c'est ce montant qu'on reprend si la course est révoquée.
      t.integer :credited_balls, default: 0, null: false
    end

    # Une activité Strava ne peut entrer qu'une fois par participation.
    add_index :trainings, %i[membership_id strava_activity_id], unique: true,
              name: "index_trainings_on_membership_and_activity"

    # Un athlète Strava = un joueur (on ne branche pas le compte d'un ami qui court plus).
    add_index :users, :strava_uid, unique: true

    # Quelle course a fait claquer ce piège / consommé cette jambe de bois : si la course
    # est révoquée (supprimée sur Strava, requalifiée), l'objet est réarmé.
    add_reference :actions, :resolved_training, foreign_key: { to_table: :trainings }, null: true
  end
end
