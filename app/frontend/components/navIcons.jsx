// Les emblèmes de la nav du bas.
//
// ⚠️ Ils ont leurs COULEURS PROPRES — ce ne sont pas des pictogrammes monochromes. Un
// pictogramme dit « maison » ; un emblème dit « le Hub de CE jeu ». C'est ce qui distingue
// une barre de navigation d'une barre d'outils, et c'est ce qu'on est venu chercher en
// regardant Clash of Clans.
//
// Conséquence : ils ne suivent plus la couleur de l'onglet. L'état actif est porté par la
// PLAQUE (indigo + libellé) et les emblèmes au repos sont simplement désaturés et atténués
// (voir `.nav .n:not(.on) .nav-svg`), comme dans les jeux dont on s'inspire.
//
// Dessinés pour être lus à **22 px** : quatre à six aplats, pas un de plus, et des couleurs
// franches. Tout détail plus fin disparaît à cette taille — les versions ×2 des maquettes
// sont trompeuses, c'est toujours la taille réelle qui tranche.
const Icon = ({ children }) => (
  <svg viewBox="0 0 24 24" className="nav-svg" role="presentation" aria-hidden>{children}</svg>
)

// Une hutte à toit de palmes : le camp, dans le décor tropical de la saison.
export const HubIcon = () => (
  <Icon>
    <path d="M12 1.6 1 10.4h3.1L12 4.2l7.9 6.2H23z" fill="#3aa76d" />
    <path d="M12 4.6 3.6 11.2h16.8z" fill="#2e8b57" />
    <rect x="4.6" y="10.8" width="14.8" height="11.6" rx="1.6" fill="#f6efe2" />
    <rect x="9.4" y="14.4" width="5.2" height="8" rx="1" fill="#8a5a2b" />
    <circle cx="12" cy="8.6" r="1.9" fill="#ff7a59" />
  </Icon>
)

export const LigueIcon = () => (
  <Icon>
    <path d="M4.6 4.2H1.6v2.2A4.4 4.4 0 0 0 5.6 10.8V8.4a2 2 0 0 1-1-1.6zM19.4 4.2h3v2.2a4.4 4.4 0 0 1-4 4.4V8.4a2 2 0 0 0 1-1.6z" fill="#c9930a" />
    <path d="M6.2 2.4h11.6v5.2a5.8 5.8 0 0 1-11.6 0z" fill="#f2b100" />
    <path d="M8.2 3.6h2.2v4a2.4 2.4 0 0 0 1 1.9l-1 1.4A4.6 4.6 0 0 1 8.2 7z" fill="#ffe08a" />
    <rect x="10.6" y="12.6" width="2.8" height="4" fill="#c9930a" />
    <rect x="6.4" y="16.4" width="11.2" height="2.6" rx="1" fill="#4a5568" />
    <rect x="4.8" y="19" width="14.4" height="3" rx="1.2" fill="#3d4757" />
  </Icon>
)

// ⚠️ Lames CLAIRES et poignées sombres : cet emblème est le seul à vivre sur le disque
// orange du combat, où un métal foncé se serait perdu.
export const CombatIcon = () => (
  <Icon>
    <path d="M4.2 1.8 1.9 4.1l11 11 2.3-2.3z" fill="#dbe3ee" />
    <path d="M19.8 1.8 22.1 4.1l-11 11-2.3-2.3z" fill="#cfd8e6" />
    <path d="M13.6 14.6 16 12.2l1.6 1.6-2.4 2.4zM10.4 14.6 8 12.2l-1.6 1.6 2.4 2.4z" fill="#2b1200" />
    <path d="M15.4 16.2 20 20.8l1.6-1.6-4.6-4.6zM8.6 16.2 4 20.8 2.4 19.2 7 14.6z" fill="#3d2000" />
  </Icon>
)

export const SacIcon = () => (
  <Icon>
    <path d="M9 1.8h6a2.8 2.8 0 0 1 2.7 2.2H6.3A2.8 2.8 0 0 1 9 1.8z" fill="#3d4757" />
    <rect x="2.4" y="5.2" width="19.2" height="16.6" rx="4" fill="#e8863a" />
    <path d="M2.4 9.2h19.2v3.6a2 2 0 0 1-2 2H4.4a2 2 0 0 1-2-2z" fill="#f6b26b" />
    <rect x="8.6" y="15" width="6.8" height="6.8" rx="1.8" fill="#c96f22" />
    <rect x="10.4" y="11.4" width="3.2" height="2.6" rx=".8" fill="#f2b100" />
  </Icon>
)

export const BoutiqueIcon = () => (
  <Icon>
    <path d="M3 10.6h18v11.2H3z" fill="#f6efe2" />
    <path d="M8.6 13.4h6.8v8.4H8.6z" fill="#5f8cbb" />
    <path d="M1.6 3.4h20.8v3.4H1.6z" fill="#e23b54" />
    <path d="M1.6 6.8h20.8l-1.4 4H3z" fill="#f4f7fd" />
    <path d="M4.6 6.8h3.2l-1 4H3.4zM11 6.8h3.2l-.4 4h-3.2zM17.4 6.8h3.2l-1.4 4h-3.2z" fill="#e23b54" />
  </Icon>
)
