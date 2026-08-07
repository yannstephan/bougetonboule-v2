# Un message peut porter un MEME (et rien d'autre : ni photo envoyée, ni URL libre).
# Le champ n'est rempli que par le sélecteur de memes, et le contrôleur vérifie que l'hôte
# appartient bien au fournisseur — sinon ce serait un champ « image quelconque » déguisé,
# avec tout ce que ça implique (contenu arbitraire embarqué, hébergement inconnu).
class AddMemeToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :meme_url, :string
    add_column :messages, :meme_title, :string
    # Le corps devient facultatif : un meme seul est un message valide.
    change_column_null :messages, :body, true
  end
end
