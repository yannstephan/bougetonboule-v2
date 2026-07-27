class AddStravaDetailsToTrainings < ActiveRecord::Migration[8.1]
  # Détails récupérés de Strava pour la page d'une sortie : ce qu'on ne stockait pas encore
  # (titre, description, temps, dénivelé, tracé du parcours, photo).
  def change
    add_column :trainings, :title,          :string
    add_column :trainings, :description,    :text
    add_column :trainings, :moving_time,    :integer   # secondes en mouvement
    add_column :trainings, :elapsed_time,   :integer   # secondes écoulées (avec pauses)
    add_column :trainings, :elevation_gain, :decimal, precision: 7, scale: 1
    add_column :trainings, :route_points,   :json      # [[lat, lng], …] décodé de la polyline Strava
    add_column :trainings, :photo_url,      :string
  end
end
