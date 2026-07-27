import { Head, Link } from '@inertiajs/react'

// Règles du jeu. Statique : le seul endroit qui décrit le fonctionnement actuel côté joueur.
// À garder à jour quand une mécanique change (voir CLAUDE.md).
const SECTIONS = [
  {
    q: '🎯 C\'est quoi le but ?',
    a: [
      'Bouge Ton Boule est un jeu de course à pied entre amis. Deux clans s\'affrontent, chacun avec son monstre.',
      'Pour l\'événement Odyssea 2027, c\'est 🌴 Fruits exotiques (monstre King-Coco) contre 🍒 Fruits rouges (monstre Dracassis).',
      'Tu cours, tu gagnes des pêches, tu t\'en sers pour attaquer le monstre adverse ou soigner le tien. Quand les PV d\'un monstre tombent à 0, son équipe perd.',
    ],
  },
  {
    q: '🍑 Comment je gagne des pêches ?',
    a: [
      'En courant, uniquement. Tes courses sont importées automatiquement depuis Strava.',
      'Règle : 1 km couru = 1 pêche, avec un maximum de 10 pêches par sortie. Inutile de faire un marathon d\'un coup — mieux vaut courir régulièrement.',
      'Les jours spéciaux (ex. Noël), les pêches sont multipliées.',
      'Tes pêches sont propres à chaque partie. Elles ne servent qu\'au combat et aux objets — jamais à acheter un avantage.',
    ],
  },
  {
    q: '⚔️ Comment marche le combat ?',
    a: [
      'Depuis l\'écran Combat, tu dépenses tes pêches : attaquer le monstre adverse (lui retire des PV) ou soigner ton monstre (lui en rend).',
      'Attaquer coûte 1 pêche, soigner en coûte 2.',
      'Un monstre protégé par un bouclier ne peut pas être attaqué tant que le bouclier tient.',
    ],
  },
  {
    q: '🎒 Les objets (power-ups)',
    a: [
      'Achetés avec tes pêches 🍑 à la boutique, rangés dans ton sac, à usage unique. Tu les déclenches quand tu veux.',
      '🌬️ Vent de dos : bonus de pêches pour toute ton équipe pendant un temps limité.',
      '🛡️ Bouclier : protège ton monstre des attaques pendant 3 h.',
      '⚡ Booster : double tes dégâts et tes soins pendant 24 h.',
      '🐺 Piège à loup : tu vises un adversaire ; les autres voient seulement « X a posé un piège à loup », jamais qui est visé.',
      '🦿 Jambe de bois : te protège d\'un piège sur ta prochaine course. Discret : personne n\'est prévenu tant qu\'elle n\'a pas déjoué un piège.',
      'Les effets à durée (vents, bouclier) sont publics : tout le monde voit qu\'une équipe en a un, et jusqu\'à quand.',
    ],
  },
  {
    q: '💎 Les diamants, c\'est quoi ?',
    a: [
      'La deuxième monnaie, celle-ci est globale (elle te suit d\'une partie à l\'autre).',
      'On en gagne avec les séries hebdo, les jours spéciaux, les coffres et la fin de partie.',
      'On ne les dépense que sur des cosmétiques. Jamais de pêches, jamais d\'avantage de combat : c\'est la règle d\'or, aucun pay-to-win.',
    ],
  },
  {
    q: '🏅 Le classement (Ligue)',
    a: [
      'Un seul classement par partie, les deux clans mélangés. Ton score = la somme des pêches de tes courses validées.',
      'Deux périodes : « Du mois » (repart à zéro le 1er de chaque mois) et « Général » (depuis le début de la partie).',
      'Le 1er du classement du mois gagne, à la fin du mois, un cosmétique tiré au hasard parmi ceux qu\'il n\'a pas encore (ou 100 💎 s\'il les possède déjà tous).',
    ],
  },
  {
    q: '🎨 Mon avatar et les cosmétiques',
    a: [
      'Ton avatar est un fruit, choisi dans la famille de ton équipe. Tu ne peux le personnaliser qu\'une fois affecté à une équipe.',
      'Plusieurs coéquipiers peuvent prendre le même fruit — l\'écran indique qui a déjà choisi quoi.',
      'Les cosmétiques (chapeau, lunettes, tenue, aura…) s\'achètent en 💎 ou se gagnent, puis s\'équipent un par emplacement depuis l\'écran Avatar.',
    ],
  },
  {
    q: '🔔 Les notifications',
    a: [
      '« Pour toi » : ce qui te concerne directement (message dans ta conversation d\'équipe, récompense de coffre ou de ligue…). Ce sont les seules poussées sur ton téléphone.',
      '« Activité de la partie » : le reste, en fil d\'activité (X a couru, X a activé un vent de dos, un piège a été posé, le chat général…). Listé, mais jamais poussé.',
      'Active les notifications push depuis l\'écran 🔔 pour recevoir les alertes « Pour toi ».',
    ],
  },
]

export default function Faq() {
  return (
    <div className="shell">
      <Head title="Règles du jeu" />
      <div className="subhead">
        <Link href="/" className="back">←</Link>
        <div className="ti">📖 Règles du jeu</div>
      </div>

      <main className="body">
        <p className="faq-intro">
          Tout ce qu'il faut savoir pour jouer. Une question en tête ? Déplie-la.
        </p>

        {SECTIONS.map((s) => (
          <details key={s.q} className="faq-item">
            <summary className="faq-q">{s.q}</summary>
            <div className="faq-a">
              {s.a.map((p, i) => <p key={i}>{p}</p>)}
            </div>
          </details>
        ))}

        <div className="faq-gold">
          <span className="faq-gold-ic">🤝</span>
          <div>
            <div className="faq-gold-t">La règle d'or</div>
            <div className="faq-gold-b">On ne gagne des pêches qu'en courant. L'argent réel n'existe pas ici, et les diamants ne touchent qu'au cosmétique : impossible d'acheter la victoire.</div>
          </div>
        </div>
      </main>
    </div>
  )
}
