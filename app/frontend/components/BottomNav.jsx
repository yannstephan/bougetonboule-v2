import { Link, usePage } from '@inertiajs/react'
import { HubIcon, LigueIcon, CombatIcon, SacIcon, BoutiqueIcon } from './navIcons'

// Les destinations du jeu. Le Chat n'est pas ici : il a rejoint les notifications dans le HUD —
// deux boutons de même nature (ce qu'on a reçu), et un onglet de moins en bas.
//
// L'onglet de la page courante s'allume : c'est LUI qui dit où l'on est, à la place du bandeau
// de titre qu'avait chaque écran. Déduit de l'URL et non d'une prop, pour qu'un écran ajouté
// plus tard ne puisse pas oublier de se déclarer.
//
// ⚠️ Chaque onglet est une PLAQUE, et seule celle de la page courante porte son libellé : les
// autres se réduisent à leur icône. C'est la barre de Clash of Clans — on lit d'un coup où
// l'on est, sans que cinq mots se disputent la largeur d'un téléphone. Le libellé s'ouvre en
// largeur (`max-width`) plutôt que d'apparaître d'un coup, sinon la barre sautait à chaque
// changement de page. Le reste ne bouge pas : plat, indigo pour l'actif, orange réservé au
// combat (voir la charte 60-30-10).
const TABS = [
  { href: '/', label: 'Hub', Icon: HubIcon },
  { href: '/ligue', label: 'Ligue', Icon: LigueIcon },
  { href: '/sac', label: 'Sac', Icon: SacIcon, alert: true },
  { href: '/boutique', label: 'Boutique', Icon: BoutiqueIcon },
]

export default function BottomNav() {
  const page = usePage()
  const { inventory_alert: bagAlert = 0 } = page.props
  const path = (page.url || '/').split('?')[0]
  // Les pages de détail (profil, sortie, admin) n'ont pas d'onglet : rien ne s'allume, et
  // c'est normal — on y arrive depuis un lien, pas depuis la barre.
  const isOn = (p) => path === p || (p !== '/' && path.startsWith(p))

  const tab = ({ href, label, Icon, alert }) => (
    <Link key={href} href={href} className={`n ${isOn(href) ? 'on' : ''}`}
          title={label} aria-label={label}>
      <span className="nav-ic">
        <Icon />
        {/* Pastille : quelque chose de neuf t'attend dans le sac (un coffre à ouvrir) */}
        {alert && bagAlert > 0 && <span className="nav-dot" aria-label="Nouveau dans ton sac" />}
      </span>
      <span className="lb">{label}</span>
    </Link>
  )

  // ⚠️ Les deux moitiés sont des CONTENEURS, pas juste un ordre d'items : elles ont la même
  // largeur (`flex:1 1 0`), quoi qu'elles contiennent. C'est ce qui garde le ⚔️ exactement au
  // milieu — sinon le libellé qui s'ouvre pousse ses voisins et le bouton central se déplace
  // d'un écran à l'autre, alors que c'est le seul dont la position doive se retenir.
  return (
    <nav className="nav">
      <div className="nav-side">{TABS.slice(0, 2).map(tab)}</div>
      <Link href="/combat" className={`center ${path.startsWith('/combat') ? 'on' : ''}`}
            title="Combattre" aria-label="Combattre">
        <CombatIcon />
      </Link>
      <div className="nav-side">{TABS.slice(2).map(tab)}</div>
    </nav>
  )
}
