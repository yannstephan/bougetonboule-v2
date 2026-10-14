import hub from '../assets/nav/hub.webp'
import ligue from '../assets/nav/ligue.webp'
import combat from '../assets/nav/combat.webp'
import sac from '../assets/nav/sac.webp'
import boutique from '../assets/nav/boutique.webp'

// Les emblèmes de la nav du bas : des ÉCUSSONS PEINTS, pas des dessins vectoriels.
//
// Ils sont servis comme les planches de monstres — des fichiers WebP dans `assets/`, un par
// destination. Même raison qu'elles : une illustration ne se paramètre pas, et vouloir la
// refaire en SVG revient à la redessiner en moins bien. On les découpe une fois et on les
// sert tels quels (~5 Ko pièce, 128 px, détourés).
//
// ⚠️ Ils portent LEUR PROPRE fond — un écusson crème cerné de blanc, un disque orange pour
// le combat. Ils se posent quand même sur une plaque : grise au repos, indigo sur l'onglet
// actif. C'est la plaque qui aligne les cinq destinations ; sans elle, les écussons flottaient
// sur le blanc de la barre et seul l'onglet actif ressemblait encore à un bouton.
// ⚠️ Le disque orange du combat est DANS l'image : le bouton n'en dessine plus.
//
// Conséquence : ils ne suivent pas la couleur de l'onglet et ne sont pas atténués au repos.
// C'est la plaque et le libellé qui disent où l'on est.
const Emblem = ({ src, alt }) => (
  <img src={src} alt="" aria-hidden className="nav-emblem" width="36" height="36"
       draggable="false" title={alt} />
)

export const HubIcon = () => <Emblem src={hub} alt="Hub" />
export const LigueIcon = () => <Emblem src={ligue} alt="Ligue" />
export const CombatIcon = () => <Emblem src={combat} alt="Combat" />
export const SacIcon = () => <Emblem src={sac} alt="Sac" />
export const BoutiqueIcon = () => <Emblem src={boutique} alt="Boutique" />
