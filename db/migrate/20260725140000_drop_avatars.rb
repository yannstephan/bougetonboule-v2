class DropAvatars < ActiveRecord::Migration[8.1]
  # L'avatar n'est plus un enregistrement : le fruit vit sur `memberships.fruit` et les
  # cosmétiques sur `user_cosmetics`. La table `avatars` (base_color / body_style) ne servait
  # plus à rien. Rien en prod, on la retire.
  def up
    drop_table :avatars
  end

  def down
    create_table :avatars do |t|
      t.string :base_color, default: "citron", null: false
      t.string :body_style, default: "default", null: false
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.timestamps
    end
  end
end
