import { Head, Link } from '@inertiajs/react'

// Règles du jeu. Statique : le seul endroit qui décrit le fonctionnement actuel côté joueur.
// À garder à jour quand une mécanique change (voir CLAUDE.md).
const SECTIONS = [
  {
    q: '🍑 Comment je gagne des boules ?',
    a: [
      'En courant, uniquement. Tes courses sont importées automatiquement depuis Strava et tes boules créditées dans la foulée.',
      'Règle : 1 km couru = 1 boule, avec un maximum de 10 boules par sortie.',
      'Le plafond s\'applique d\'abord, les multiplicateurs ensuite. Exemple : une sortie de 15 km vaut 10 boules ; avec un vent de dos actif, 10 × 1,5 = 15 boules.',
      'Les journées spéciales (5-6 dans la saison, annoncées ou surprises) doublent tout : boules ET plafond. 15 km un jour ×2 = 20 boules, et avec un vent de dos… fais le calcul 😉',
      'Ton porte-monnaie est plafonné à 100 boules : une course ne remplit que jusqu\'à 100, le surplus est perdu (tu es prévenu). Le classement, lui, compte bien toutes les boules de tes courses. Morale : dépense tes boules !',
      'Tes boules sont propres à chaque partie. Elles ne servent qu\'au combat et aux objets — jamais à acheter un avantage.',
    ],
  },
  {
    q: '⚔️ Comment marche le combat ?',
    a: [
      'Depuis l\'écran Combat, tu dépenses tes boules : attaquer coûte 1 boule et retire 10 PV au monstre adverse ; soigner coûte 2 boules et rend 10 PV au tien.',
      'Ces 10 PV sont multipliés par la jauge de meute de ton équipe (voir plus bas) : à meute +40 %, chaque attaque fait 14 PV.',
      'Un monstre coiffé d\'un saladier ne peut pas être attaqué tant que le saladier tient.',
      '🩹 Les monstres encaissent : la première fois qu\'ils passent sous 75 %, 50 % puis 25 % de leurs PV, leur dessin s\'abîme d\'un cran (couronne de travers, coque fendue, drupéoles perdues, regard qui part en vrille). Les cicatrices sont définitives — un soin remonte les PV, pas la façade.',
      '💥 Échec critique : une attaque sur dix rate — le monstre te mord et tu perds 15 % de ton solde de boules (au moins 1, au plus 10), sans infliger de dégât. Garder un gros magot rend la morsure plus douloureuse…',
      '💨 Second souffle : la première fois que ton monstre passe sous 25 % de ses PV, tes soins ne coûtent plus que 1 boule pendant 7 jours. Une seule fois par saison — le baroud d\'honneur.',
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
      'Achetés avec tes boules 🍑 à la boutique, rangés dans ton sac, à usage unique. Tu les déclenches quand tu veux.',
      '🐺 Piège à loup (5 🍑) : tu vises un adversaire ; sa prochaine course rapporte 0 boule. Les autres voient seulement « X a posé un piège à loup », jamais qui est visé.',
      '🦿 Jambe de bois (4 🍑) : déjoue le prochain piège sur ta course — tu gardes tes boules. Discrète : personne n\'est prévenu tant qu\'elle n\'a pas servi.',
      '🌬️ Vent de dos (4 🍑) : ×1,5 sur les boules de toute ton équipe pendant 12 h. À déclencher avant les sorties du week-end !',
      '🌪️ Vent de face (4 🍑) : −25 % sur les boules de l\'équipe adverse pendant 12 h. Les victimes sont prévenues — c\'est une déclaration de guerre assumée.',
      '🥣 Saladier (6 🍑) : un saladier retourné sur ton monstre — il est intouchable pendant 6 h et tu le vois sous sa cloche. L\'arme anti-raid.',
      '🍦 Chantilly (4 🍑) : aveugle l\'équipe adverse pendant 24 h et tu choisis quel monstre barbouiller — le tien ou le sien. Elle en a plein les yeux dans son avatar, et ses PV s\'affichent « ??? ». Idéal pour cacher une offensive surprise.',
      'Les effets à durée (vents, saladier, chantilly) sont publics : tout le monde voit qu\'une équipe en a un, et jusqu\'à quand.',
      'Pas d\'empilement : un effet à durée ne se relance pas tant qu\'il tourne (pas deux chantilly, deux vents ni deux saladiers en même temps). Attends qu\'il se termine pour en reposer un.',
    ],
  },
  {
    q: '💎 Les diamants, c\'est quoi ?',
    a: [
      'La deuxième monnaie, celle-ci est globale (elle te suit d\'une partie à l\'autre).',
      'On en gagne surtout avec la série hebdo (voir ci-dessous), et aussi via les coffres, le classement et la fin de partie.',
      'On ne les dépense que sur des cosmétiques. Jamais de boules, jamais d\'avantage de combat : c\'est la règle d\'or, aucun pay-to-win.',
    ],
  },
  {
    q: '🔥 La série hebdo (streak)',
    a: [
      'Cours au moins une fois par semaine (du lundi au dimanche) et ta série grandit. Chaque lundi, elle paie en diamants : 10 💎 la 1re semaine, puis 20, 30, 40 et 50 — et 50 💎 chaque semaine ensuite.',
      '🎁 Toutes les 5 semaines de série (5, 10, 15…), palier bonus : un cosmétique tiré au hasard parmi ceux que tu n\'as pas (ou 100 💎 si tu as déjà tout) — et tu gagnes un joker.',
      '🧊 Le joker (2 max en réserve) te sauve une semaine sans course : il se consomme et ta série est gelée au lieu de repartir à zéro. Blessure, vacances… tu ne perds pas tout.',
      'Semaine sans course et sans joker : la série retombe à zéro. Les jokers ne s\'achètent pas — ils se courent.',
      'Ta série est propre à chaque partie, mais les diamants gagnés sont à toi pour toujours.',
    ],
  },
  {
    q: '🎁 Les coffres',
    a: [
      'Chaque course importée peut cacher un coffre (une chance sur ~7, maximum un par jour). Et au bout de 7 courses sans rien trouver, le suivant est garanti — la malchance a une limite.',
      'Quatre raretés : commun, rare, épique, légendaire. Plus c\'est rare, plus il y a de diamants dedans — et plus il y a de chances d\'y trouver un cosmétique que tu n\'as pas (toujours dans un légendaire).',
      'Le coffre t\'attend sur le Hub : appuie sur « Ouvrir » pour découvrir ce qu\'il contient. Certains cosmétiques ne se trouvent QUE dans les coffres…',
    ],
  },
  {
    q: '🏅 Le classement (Ligue)',
    a: [
      'Un seul classement par partie, les deux clans mélangés. Ton score = la somme des boules de tes courses (les courses piégées comptent pour 0 — raison de plus pour garder une jambe de bois).',
      'Deux périodes : « Du mois » (repart à zéro le 1er de chaque mois) et « Général » (depuis le début de la partie).',
      'Le 1er du classement du mois gagne, à la fin du mois, un cosmétique tiré au hasard parmi ceux qu\'il n\'a pas encore (ou 100 💎 s\'il les possède déjà tous).',
    ],
  },
  {
    q: '🎨 Mon avatar et les cosmétiques',
    a: [
      'Ton avatar est un fruit, choisi dans la famille de ton équipe. Tu ne peux le personnaliser qu\'une fois affecté à une équipe.',
      'Plusieurs coéquipiers peuvent prendre le même fruit — l\'écran indique qui a déjà choisi quoi.',
      'Les cosmétiques (chapeau, lunettes, tenue, bras, jambes, aura) s\'achètent en 💎 ou se gagnent, puis s\'équipent un par emplacement depuis l\'écran Avatar.',
      'Certaines pièces ne sont jamais en vente : elles ne se gagnent que par les coffres, les séries, la ligue ou les événements de la saison. L\'🐺 Esprit du loup, par exemple, ne sort que des coffres…',
    ],
  },
  {
    q: '🔔 Les notifications',
    a: [
      '« Pour toi » : ce qui te concerne directement — message d\'équipe, récompense, palier de meute, monstre affamé, vent de face ou chantilly reçue, et tout ce qui touche aux pièges (ta course piégée, ton piège réussi ou déjoué). Ce sont les seules poussées sur ton téléphone.',
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
        <div className="faq-hero">
          <div className="faq-hero-vs"><span>🌴</span><b>VS</b><span>🍒</span></div>
          <p>
            La guerre du verger a commencé. D'un côté, les <b>🌴 Fruits exotiques</b>, menés
            par <b>King-Coco</b>, le roi noix de coco. De l'autre, les <b>🍒 Fruits rouges</b>,
            rassemblés derrière <b>Framboitrix</b>, la sorcière framboise. Toi, tu es un fruit
            de ton clan — ananas, fraise, kiwi, cerise… — et ton arme pousse au bout de tes
            baskets : <b>chaque kilomètre couru fait pousser une boule 🍑</b>.
          </p>
          <p>
            Avec tes boules, <b>attaque le monstre adverse ou soigne le tien</b> (10 000 PV
            chacun). Un monstre à 0 PV, et son clan tombe sur-le-champ ; sinon, au dernier jour
            de la saison, le monstre le mieux portant offre la victoire aux siens. En chemin :
            des objets pour piéger l'autre camp, des séries et des coffres pleins de
            diamants 💎 pour bichonner ton fruit. Une seule loi au verger : <b>tout se gagne
            en courant</b>, rien ne s'achète.
          </p>
        </div>

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
            <div className="faq-gold-b">On ne gagne des boules qu'en courant. L'argent réel n'existe pas ici, et les diamants ne touchent qu'au cosmétique : impossible d'acheter la victoire. Même le booster de meute se gagne en baskets.</div>
          </div>
        </div>
      </main>
    </div>
  )
}
