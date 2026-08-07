// La rareté d'une pièce, côté texte. Sa COULEUR vit dans application.css (section « Rareté »),
// et la classe `rar-<clé>` fait le pont entre les deux : un composant ne connaît jamais un
// vert ni un or, il pose la classe et lit --rar / --rar-ink.
// Les libellés étaient recopiés dans la boutique et dans le coffre — un seul endroit, donc.
export const RARITY_LABEL = { common: 'Commun', rare: 'Rare', epic: 'Épique', legendary: 'Légendaire' }

export const rarityLabel = (r) => RARITY_LABEL[r] || r
// Variante pour l'intérieur d'une phrase (« un coffre légendaire t'attend »).
export const rarityWord = (r) => rarityLabel(r).toLowerCase()
