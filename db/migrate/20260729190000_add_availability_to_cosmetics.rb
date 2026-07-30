class AddAvailabilityToCosmetics < ActiveRecord::Migration[8.1]
  # Fenêtre de disponibilité d'un cosmétique — c'est ce qui fait la « boutique de saison ».
  # Les deux bornes sont facultatives et indépendantes :
  #   les deux vides  → pièce permanente (le cas de la grande majorité du catalogue) ;
  #   `until` seule   → disparaît à cette date ;
  #   `from` seule    → n'apparaît qu'à partir de cette date ;
  #   les deux        → collection éphémère (Halloween, Noël…).
  # La fenêtre vaut aussi pour les TIRAGES (coffre, streak, ligue) : un bonnet de Noël ne
  # doit pas tomber en juillet.
  def change
    add_column :cosmetics, :available_from, :datetime
    add_column :cosmetics, :available_until, :datetime
  end
end
