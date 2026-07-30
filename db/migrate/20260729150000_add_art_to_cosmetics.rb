class AddArtToCosmetics < ActiveRecord::Migration[8.1]
  # Clé d'un dessin SVG (components/cosmeticArt.jsx) qui remplace l'emoji quand celui-ci
  # ne peut pas faire le travail : une paire de chaussures DE FACE (👟 n'existe qu'en
  # profil, et seul), ou une pièce dont l'emoji est un visage entier (🤠, 🧐, 🎅) qui
  # viendrait se coller sur celui du fruit. Vide = on rend `emoji`, comme avant.
  def change
    add_column :cosmetics, :art, :string
  end
end
