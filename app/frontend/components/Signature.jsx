// La signature du jeu : le seul endroit où l'app se NOMME une fois qu'on est connecté.
// Les écrans n'ont pas de bandeau de titre (c'est l'icône allumée du HUD qui dit où l'on est),
// donc le nom n'a aucune place en haut — il se pose en pied des deux écrans où l'on vient
// chercher de l'information sur le jeu plutôt que du jeu : les règles (/faq) et le compte
// (/avatar). Composant partagé pour que les deux ne divergent pas.
export default function Signature() {
  return (
    <footer className="sig">
      <span className="sig-ic">🍑</span>
      <b>Bouge Ton Boule</b>
      <span>La course à pied entre amis</span>
    </footer>
  )
}
