class RenameSmokeAndShieldItems < ActiveRecord::Migration[8.1]
  # Le fumigène devient la Chantilly (elle gicle dans les yeux du monstre visé) et le bouclier
  # devient le Saladier (retourné sur le monstre). Seuls les libellés changent : les
  # `effect_type` ("smoke" / "shield") restent la clé technique partout dans le code.
  def up
    rename_item("Fumigène", "Chantilly", "Chantilly plein les yeux : masque les PV d'un monstre à l'équipe adverse (24h)")
    rename_item("Bouclier", "Saladier", "Saladier retourné sur ton monstre : intouchable pendant 6h")
  end

  def down
    rename_item("Chantilly", "Fumigène", "Masque les PV d'un monstre aux yeux de l'équipe adverse (24h)")
    rename_item("Saladier", "Bouclier", "Monstre intouchable pendant 6h")
  end

  private

  def rename_item(from, to, description)
    execute ActiveRecord::Base.sanitize_sql([
      "UPDATE items SET name = ?, description = ? WHERE name = ?", to, description, from
    ])
  end
end
