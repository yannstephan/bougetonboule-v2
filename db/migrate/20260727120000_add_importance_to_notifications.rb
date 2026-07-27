class AddImportanceToNotifications < ActiveRecord::Migration[8.1]
  # Deux niveaux : "important" (poussé + listé) et "secondary" (listé seulement, jamais poussé).
  # Défaut secondaire : une notif n'est poussée que si on le décide explicitement.
  def change
    add_column :notifications, :importance, :string, default: "secondary", null: false
  end
end
