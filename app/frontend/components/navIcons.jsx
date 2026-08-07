// Les emblèmes de la nav du bas.
//
// ⚠️ Ils ont leurs COULEURS PROPRES — ce ne sont pas des pictogrammes monochromes. Un
// pictogramme dit « maison » ; un emblème dit « le Hub de CE jeu ». C'est ce qui distingue
// une barre de navigation d'une barre d'outils.
//
// ⚠️ Chacun porte un CONTOUR sombre commun (`INK`), et c'est lui qui fait tout le contraste :
// sans lui, des aplats clairs sur une plaque claire donnaient des emblèmes fantômes, et sur
// la plaque indigo ils se noyaient dans le bleu. Un seul trait, la même encre partout —
// c'est aussi ce qui les fait ressembler à une FAMILLE plutôt qu'à cinq dessins voisins.
//
// Conséquence : ils ne suivent pas la couleur de l'onglet et ne sont PAS atténués au repos.
// L'état actif est porté par la plaque (indigo + libellé), ce qui suffit largement — les
// désaturer en plus ne faisait que les rendre illisibles.
//
// Dessinés pour être lus à **25 px** : quatre à six aplats, pas un de plus, des couleurs
// franches et des formes qui remplissent la boîte. Tout détail plus fin disparaît à cette
// taille — une maquette agrandie est trompeuse, c'est la taille réelle qui tranche.
const INK = '#2f3545'

const Icon = ({ children }) => (
  <svg viewBox="0 0 24 24" className="nav-svg" role="presentation" aria-hidden>{children}</svg>
)

// Une hutte à toit de palmes : le camp, dans le décor tropical de la saison.
export const HubIcon = () => (
  <Icon>
    <path d="M12 1 .8 10.6l1.8 2.1L12 4.6l9.4 8.1 1.8-2.1z" fill="#2e8b57" stroke={INK} strokeWidth="1.1" strokeLinejoin="round" />
    <path d="M5 12h14v10.4H5z" fill="#f3e7d2" stroke={INK} strokeWidth="1.1" strokeLinejoin="round" />
    <path d="M9.6 15.4h4.8v7H9.6z" fill="#8a5a2b" stroke={INK} strokeWidth="1.1" strokeLinejoin="round" />
    <circle cx="12" cy="9" r="2" fill="#ff7a59" stroke={INK} strokeWidth="1.1" />
  </Icon>
)

export const LigueIcon = () => (
  <Icon>
    <path d="M4.6 3.4H1.2v3A4.9 4.9 0 0 0 5.6 11.2M19.4 3.4h3.4v3a4.9 4.9 0 0 1-4.4 4.8"
          fill="none" stroke={INK} strokeWidth="2.2" strokeLinecap="round" />
    <path d="M5.4 1.6h13.2v6.2a6.6 6.6 0 0 1-13.2 0z" fill="#f2b100" stroke={INK} strokeWidth="1.2" strokeLinejoin="round" />
    <path d="M7.8 3.4h2.4v4.4a3 3 0 0 0 1.2 2.3l-1.3 1.6A5.4 5.4 0 0 1 7.8 7z" fill="#ffe08a" />
    <path d="M10.2 13.4h3.6v3.4h-3.6z" fill="#c9930a" stroke={INK} strokeWidth="1.1" />
    <path d="M4.6 18.4h14.8v3.8H4.6z" fill="#4a5568" stroke={INK} strokeWidth="1.2" strokeLinejoin="round" />
  </Icon>
)

// ⚠️ Lames CLAIRES et poignées sombres : cet emblème est le seul à vivre sur le disque
// orange du combat, où un métal foncé se serait perdu.
export const CombatIcon = () => (
  <Icon>
    <path d="M3.6 1.2 1.2 3.6l11.2 11.2 2.4-2.4z" fill="#eef3fa" stroke={INK} strokeWidth="1.1" strokeLinejoin="round" />
    <path d="M20.4 1.2 22.8 3.6 11.6 14.8 9.2 12.4z" fill="#dde5f0" stroke={INK} strokeWidth="1.1" strokeLinejoin="round" />
    <path d="M13.2 14.6 16.2 11.6l2 2-3 3zM10.8 14.6 7.8 11.6l-2 2 3 3z" fill="#3a1d00" stroke={INK} strokeWidth="1" strokeLinejoin="round" />
    <path d="M15.6 16.4 20.4 21.2l1.8-1.8-4.8-4.8zM8.4 16.4 3.6 21.2 1.8 19.4l4.8-4.8z" fill="#5a3410" stroke={INK} strokeWidth="1" strokeLinejoin="round" />
  </Icon>
)

export const SacIcon = () => (
  <Icon>
    <path d="M8.4 1.2h7.2a3.4 3.4 0 0 1 3.2 2.6H5.2A3.4 3.4 0 0 1 8.4 1.2z" fill="#4a5568" stroke={INK} strokeWidth="1.1" strokeLinejoin="round" />
    <rect x="1.8" y="4.6" width="20.4" height="18" rx="4.4" fill="#e0761f" stroke={INK} strokeWidth="1.2" />
    <path d="M2 9.4h20v4a2.2 2.2 0 0 1-2.2 2.2H4.2A2.2 2.2 0 0 1 2 13.4z" fill="#f7ab5c" stroke={INK} strokeWidth="1.1" strokeLinejoin="round" />
    <rect x="8.2" y="16.4" width="7.6" height="6.2" rx="1.8" fill="#b85e14" stroke={INK} strokeWidth="1.1" />
    <rect x="10.2" y="11.6" width="3.6" height="2.8" rx=".9" fill="#ffd35c" stroke={INK} strokeWidth="1" />
  </Icon>
)

export const BoutiqueIcon = () => (
  <Icon>
    <path d="M2.6 11h18.8v11.4H2.6z" fill="#f3e7d2" stroke={INK} strokeWidth="1.2" strokeLinejoin="round" />
    <path d="M8.4 14h7.2v8.4H8.4z" fill="#4a7fd1" stroke={INK} strokeWidth="1.1" strokeLinejoin="round" />
    <path d="M1 2.4h22v4.2H1z" fill="#d62b45" stroke={INK} strokeWidth="1.2" strokeLinejoin="round" />
    <path d="M1 6.6h22l-1.6 4.6H2.6z" fill="#fbfdff" stroke={INK} strokeWidth="1.2" strokeLinejoin="round" />
    <path d="M4.6 6.6h3.6l-1.1 4.6H3.2zM11.4 6.6H15l-.4 4.6h-3.6zM18.2 6.6h3.6l-1.6 4.6H17z" fill="#d62b45" />
  </Icon>
)
