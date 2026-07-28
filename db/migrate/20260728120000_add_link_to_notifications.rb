class AddLinkToNotifications < ActiveRecord::Migration[8.1]
  # Lien facultatif vers l'écran concerné par la notification (ex. la page d'une course).
  # Rend la carte de notification cliquable côté front.
  def change
    add_column :notifications, :link, :string
  end
end
