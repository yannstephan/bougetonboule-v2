import { Head, Link } from '@inertiajs/react'

// Règles du jeu. Statique : le seul endroit qui décrit le fonctionnement actuel côté joueur.
// À garder à jour quand une mécanique change (voir CLAUDE.md).
const SECTIONS = [
  {
    q: '🎯 C\'est quoi le but ?',
    a: [
      'Bouge Ton Boule est un jeu de course à pied entre amis. Deux clans s\'affrontent, chacun avec son monstre de 10 000 PV.',
      'Pour l\'événement Odyssea 2027, c\'est 🌴 Fruits exotiques (monstre King-Coco) contre 🍒 Fruits rouges (monstre Framboitrix).',
      'Tu cours, tu gagnes des pêches, tu t\'en sers pour attaquer le monstre adverse ou soigner le tien.',
      'La partie se termine de deux façons : si un monstre tombe à 0 PV, son équipe perd immédiatement. Sinon, au dernier jour de la saison, l\'équipe dont le monstre a le plus haut pourcentage de PV gagne. Il y a toujours un vainqueur (ou une égalité parfaite) — le suspense dure jusqu\'au bout.',
    ],
  },
  {
    q: '🍑 Comment je gagne des pêches ?',
    a: [
      'En courant, uniquement. Tes courses sont importées automatiquement depuis Strava et tes pêches créditées dans la foulée.',
      'Règle : 1 km couru = 1 pêche, avec un maximum de 10 pêches par sortie.',
      'Le plafond s\'applique d\'abord, les multiplicateurs ensuite. Exemple : une sortie de 15 km vaut 10 pêches ; avec un vent de dos actif, 10 × 1,5 = 15 pêches.',
      'Les journées spéciales (5-6 dans la saison, annoncées ou surprises) doublent tout : pêches ET plafond. 15 km un jour ×2 = 20 pêches, et avec un vent de dos… fais le calcul 😉',
      'Ton porte-monnaie est plafonné à 100 pêches : une course ne remplit que jusqu\'à 100, le surplus est perdu (tu es prévenu). Le classement, lui, compte bien toutes les pêches de tes courses. Morale : dépense tes pêches !',
      'Tes pêches sont propres à chaque partie. Elles ne servent qu\'au combat et aux objets — jamais à acheter un avantage.',
    ],
  },
  {
    q: '⚔️ Comment marche le combat ?',
    a: [
      'Depuis l\'écran Combat, tu dépenses tes pêches : attaquer coûte 1 pêche et retire 10 PV au monstre adverse ; soigner coûte 2 pêches et rend 10 PV au tien.',
      'Ces 10 PV sont multipliés par la jauge de meute de ton équipe (voir plus bas) : à meute +40 %, chaque attaque fait 14 PV.',
      'Un monstre protégé par un bouclier ne peut pas être attaqué tant que le bouclier tient.',
      '💥 Échec critique : une attaque sur dix rate — le monstre te mord et tu perds 15 % de ton solde de pêches (au moins 1, au plus 10), sans infliger de dégât. Garder un gros magot rend la morsure plus douloureuse…',
      '💨 Second souffle : la première fois que ton monstre passe sous 25 % de ses PV, tes soins ne coûtent plus que 1 pêche pendant 7 jours. Une seule fois par saison — le baroud d\'honneur.',
    ],
  },
  {
    q: '🐾 La jauge de meute (le booster d\'équipe)',
    a: [
      'Chaque semaine où au moins 5 coéquipiers ont couru chacun 10 km ou plus, ton équipe gagne un palier de meute : +10 % permanents sur les attaques ET les soins.',
      'Les paliers s\'additionnent et ne se perdent jamais, jusqu\'à un maximum de +100 % (attaques et soins doublés).',
      'C\'est le seul « booster » du jeu, et il ne s\'achète pas : il se gagne en courant à plusieurs. Le 5e coureur de la semaine vaut de l\'or — allez chercher les copains qui hésitent !',
      'Le verdict tombe chaque lundi matin, et la jauge des deux équipes est visible par tout le monde.',
    ],
  },
  {
    q: '🍽️ Le monstre affamé',
    a: [
      'Ton monstre se nourrit de vos courses. Si personne dans l\'équipe ne court pendant 3 jours, il commence à dépérir : −50 PV par jour de jeûne.',
      'Un avertissement 🍽️ apparaît sur le Hub dès 48 h sans course.',
      'La famine ne peut pas le tuer (elle s\'arrête à 5 % des PV max) — mais elle le laisse à la merci de l\'équipe adverse. Le seul remède : aller courir.',
    ],
  },
  {
    q: '🎒 Les objets (power-ups)',
    a: [
      'Achetés avec tes pêches 🍑 à la boutique, rangés dans ton sac, à usage unique. Tu les déclenches quand tu veux.',
      '🐺 Piège à loup (5 🍑) : tu vises un adversaire ; sa prochaine course rapporte 0 pêche. Les autres voient seulement « X a posé un piège à loup », jamais qui est visé.',
      '🦿 Jambe de bois (4 🍑) : déjoue le prochain piège sur ta course — tu gardes tes pêches. Discrète : personne n\'est prévenu tant qu\'elle n\'a pas servi.',
      '🌬️ Vent de dos (4 🍑) : ×1,5 sur les pêches de toute ton équipe pendant 12 h. À déclencher avant les sorties du week-end !',
      '🌪️ Vent de face (4 🍑) : −25 % sur les pêches de l\'équipe adverse pendant 12 h. Les victimes sont prévenues — c\'est une déclaration de guerre assumée.',
      '🛡️ Bouclier (6 🍑) : ton monstre est intouchable pendant 6 h. L\'arme anti-raid.',
      '🌫️ Fumigène (4 🍑) : aveugle l\'équipe de ton choix pendant 24 h — elle ne voit plus les PV des monstres (affichés « ??? »). Idéal avant une offensive surprise.',
      'Les effets à durée (vents, bouclier, fumée) sont publics : tout le monde voit qu\'une équipe en a un, et jusqu\'à quand.',
    ],
  },
  {
    q: '💎 Les diamants, c\'est quoi ?',
    a: [
      'La deuxième monnaie, celle-ci est globale (elle te suit d\'une partie à l\'autre).',
      'On en gagne avec les séries hebdo, les journées spéciales, les coffres et la fin de partie.',
      'On ne les dépense que sur des cosmétiques. Jamais de pêches, jamais d\'avantage de combat : c\'est la règle d\'or, aucun pay-to-win.',
    ],
  },
  {
    q: '🏅 Le classement (Ligue)',
    a: [
      'Un seul classement par partie, les deux clans mélangés. Ton score = la somme des pêches de tes courses (les courses piégées comptent pour 0 — raison de plus pour garder une jambe de bois).',
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
      '« Pour toi » : ce qui te concerne directement — message d\'équipe, récompense, palier de meute, monstre affamé, vent de face ou fumigène reçu, et tout ce qui touche aux pièges (ta course piégée, ton piège réussi ou déjoué). Ce sont les seules poussées sur ton téléphone.',
      '« Activité de la partie » : le reste, en fil d\'activité (X a couru et ce que ça lui rapporte, X a activé un vent de dos, un piège a été posé…). Listé, mais jamais poussé.',
      'Le chat général ne crée pas de notification : les messages non lus (équipe + général) sont signalés par une pastille sur l\'onglet Chat.',
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
            <div className="faq-gold-b">On ne gagne des pêches qu'en courant. L'argent réel n'existe pas ici, et les diamants ne touchent qu'au cosmétique : impossible d'acheter la victoire. Même le booster de meute se gagne en baskets.</div>
          </div>
        </div>
      </main>
    </div>
  )
}
