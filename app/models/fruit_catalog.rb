# Catalogue des fruits jouables, groupés par famille d'équipe.
#
# La clé (`key`) est la source de vérité partagée avec le front : le composant SVG
# `FruitAvatar.jsx` dessine chaque fruit à partir de cette même clé. Toute clé ajoutée
# ici doit avoir son pendant visuel là-bas (sinon fruit rendu générique).
module FruitCatalog
  FAMILIES = {
    "exotiques" => {
      label: "Fruits exotiques",
      monster: "king-coco",
      fruits: [
        { key: "ananas",    name: "Ananas" },
        { key: "mangue",    name: "Mangue" },
        { key: "papaye",    name: "Papaye" },
        { key: "banane",    name: "Banane" },
        { key: "passion",   name: "Fruit de la passion" },
        { key: "litchi",    name: "Litchi" },
        { key: "kiwi",      name: "Kiwi" },
        { key: "dragon",    name: "Fruit du dragon" },
        { key: "carambole", name: "Carambole" },
        { key: "goyave",    name: "Goyave" },
        { key: "durian",    name: "Durian" },
        { key: "corossol",  name: "Corossol" }
      ]
    },
    "rouges" => {
      label: "Fruits rouges",
      monster: "dracassis",
      fruits: [
        { key: "fraise",          name: "Fraise" },
        { key: "fraise_des_bois", name: "Fraise des bois" },
        { key: "framboise",       name: "Framboise" },
        { key: "cerise",          name: "Cerise" },
        { key: "mure",            name: "Mûre" },
        { key: "myrtille",        name: "Myrtille" },
        { key: "groseille",       name: "Groseille" },
        { key: "grenade",         name: "Grenade" },
        { key: "cranberry",       name: "Cranberry" },
        { key: "goji",            name: "Baie de goji" },
        { key: "sureau",          name: "Baie de sureau" }
      ]
    }
  }.freeze

  FAMILY_KEYS = FAMILIES.keys.freeze

  module_function

  def family(family_key) = FAMILIES[family_key]

  def fruits_for(family_key) = FAMILIES.dig(family_key, :fruits) || []

  def keys_for(family_key) = fruits_for(family_key).map { |f| f[:key] }

  def monster_for(family_key) = FAMILIES.dig(family_key, :monster)

  # Nom lisible d'un fruit, quelle que soit sa famille.
  def name_for(fruit_key)
    return nil if fruit_key.blank?

    FAMILIES.each_value do |fam|
      found = fam[:fruits].find { |f| f[:key] == fruit_key }
      return found[:name] if found
    end
    nil
  end
end
