class CreateCosmeticSets < ActiveRecord::Migration[8.1]
  def change
    # Une PANOPLIE : un thème, plusieurs pièces, toutes de la même rareté. On achète
    # toujours à la pièce — la panoplie range le rayon et porte les PROMOTIONS, qui sont
    # le seul endroit d'où un prix peut bouger sans redéployer.
    create_table :cosmetic_sets do |t|
      t.string :name, null: false
      t.string :description
      # La promo : un pourcentage et une fenêtre. Les trois vides = pas de promo.
      t.integer :promo_percent
      t.datetime :promo_from
      t.datetime :promo_until
      t.timestamps
    end
    add_index :cosmetic_sets, :name, unique: true

    add_reference :cosmetics, :cosmetic_set, foreign_key: true
  end
end
