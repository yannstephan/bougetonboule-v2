// Les icônes de la nav du bas, dessinées à plat.
//
// ⚠️ Dessinées et non en emoji pour UNE raison : elles doivent prendre la couleur de leur
// onglet (`currentColor`) — l'encre de la plaque indigo quand il est actif, le gris muet
// sinon. Un emoji garde ses couleurs quoi qu'il arrive, et ne se dessine pas pareil d'un
// téléphone à l'autre. C'est la seule famille d'icônes du jeu qui a besoin de ça : partout
// ailleurs (objets, effets, cosmétiques), l'emoji EST l'identité de la chose.
//
// Les détails secondaires (anses de la coupe, poche du sac, poignées des épées) sont peints
// dans la MÊME couleur à opacité réduite : ils restent lisibles sur n'importe quel fond,
// alors qu'une seconde couleur en dur jurerait sur la plaque active.
const Icon = ({ children }) => (
  <svg viewBox="0 0 24 24" className="nav-svg" fill="currentColor" role="presentation" aria-hidden>
    {children}
  </svg>
)

export const HubIcon = () => (
  <Icon><path d="M12 2.4 1.6 11.2h3V21h5.2v-5.6h4.4V21h5.2v-9.8h3z" /></Icon>
)

export const LigueIcon = () => (
  <Icon>
    <path d="M6.5 3h11v4.8a5.5 5.5 0 0 1-4.5 5.4V17h3.2a1 1 0 0 1 1 1v2.4H6.8V18a1 1 0 0 1 1-1H11v-3.8A5.5 5.5 0 0 1 6.5 7.8z" />
    <path d="M5 4.6H1.9v2.1A4 4 0 0 0 5.4 10.7V8.3A1.9 1.9 0 0 1 5 7.1zM19 4.6h3.1v2.1a4 4 0 0 1-3.5 4V8.3a1.9 1.9 0 0 0 .4-1.2z" opacity=".5" />
  </Icon>
)

export const CombatIcon = () => (
  <Icon>
    <path d="M3.4 2.6 2 4l10.2 10.2 1.4-1.4zm17.2 0L22 4 11.8 14.2l-1.4-1.4z" />
    <path d="M14.6 15.4 16 14l5 5-1.4 1.4zm-5.2 0L8 14l-5 5 1.4 1.4z" opacity=".55" />
  </Icon>
)

export const SacIcon = () => (
  <Icon>
    <path d="M9.2 2h5.6a2.6 2.6 0 0 1 2.5 2H6.7A2.6 2.6 0 0 1 9.2 2z" />
    <path d="M6 5.4h12a3.4 3.4 0 0 1 3.4 3.4v9.2A3.4 3.4 0 0 1 18 21.4H6a3.4 3.4 0 0 1-3.4-3.4V8.8A3.4 3.4 0 0 1 6 5.4z" />
    <rect x="8.8" y="11.6" width="6.4" height="6" rx="1.6" opacity=".45" />
  </Icon>
)

export const BoutiqueIcon = () => (
  <Icon>
    <path d="M3.6 3h16.8l1.8 4.6a3.1 3.1 0 0 1-6 1.1 3.1 3.1 0 0 1-6.1 0 3.1 3.1 0 0 1-6.1 0A3.1 3.1 0 0 1 1.8 7.6z" />
    <path d="M4.4 11.4a4.6 4.6 0 0 0 2.1-.5v10.1h11V10.9a4.6 4.6 0 0 0 2.1.5v10.6H4.4z" opacity=".55" />
  </Icon>
)
