# Bouge Ton Boule v2 — Contexte projet

> Ce fichier est lu automatiquement par Claude Code. Il résume le jeu, la stack,
> le modèle de données, ce qui est déjà construit, le design et la roadmap.

## Le concept

Jeu de **course à pied entre amis**. Chaque km couru (importé depuis **Strava**) rapporte
**1 boule 🍑** (max 10 / sortie). ⚠️ **Vocabulaire** : la monnaie s'appelle la **boule**
(féminin — c'est Bouge Ton Boule), illustrée par l'emoji pêche 🍑 — écrire « boules »,
jamais « pêches », dans tous les textes joueurs. On dépense ses boules pour **attaquer** le monstre de
l'équipe adverse (10 000 PV) ou **soigner** le sien. Un monstre à 0 PV = défaite immédiate ;
sinon, à la date de fin de la partie, l'équipe au plus haut **% de PV** gagne (`FinishGame`).
C'est la v2 (front moderne) d'une app Rails existante jugée trop brouillonne.
**Tout l'équilibrage vit dans `GameRules`** (app/models), calibré sur le dump de la saison v1.

L'événement **Odyssea 2027** (mars 2027) oppose deux clans : **🌴 Fruits exotiques** (monstre
**King-Coco**) vs **🍒 Fruits rouges** (monstre **Framboitrix**). Chaque joueur choisit un
**fruit-avatar** dans la famille de son équipe (voir plus bas).

## Stack

- **Rails 8.1** + **Inertia.js** + **React** (Vite) + **Tailwind v4**, base **SQLite**
- **Solid Queue/Cache/Cable** (pas de Redis), **Kamal** pour le déploiement, stubs **PWA**
- Auth maison par session : email/mot de passe (`has_secure_password`) + **Google** (OmniAuth)
- Ruby **3.3.6** recommandé (voir `.ruby-version`) — non verrouillé strictement par Bundler
- Objectif hébergement : **~5-6 €/mois** (VPS Hetzner + SQLite, webhooks, PWA), voir plus bas

## Économie (règle d'or : jamais de pay-to-win)

| Monnaie | Gagnée par | Dépensée en | Portée |
|---|---|---|---|
| 🍑 **Boules** | **courir uniquement** (1/km, max 10) | combat + power-ups | **par partie** (`Membership.balls`) |
| 💎 **Diamants** | streaks, jours spéciaux, coffres, fin de partie | **cosmétiques uniquement** | **globale** (`User.diamonds`) |

On n'achète jamais de boules ni d'avantage de combat. Les 💎 ne touchent qu'au cosmétique.
Le seul « booster » (jauge de meute) se **gagne en courant à plusieurs** — jamais acheté.

**Scoring d'une course** (`TrainingScorer`) : plafonds d'abord, multiplicateurs ensuite —
15 km = 10 🍑, ×1,5 avec un vent de dos = 15 🍑. Un jour spécial ×2 double aussi les plafonds
effectifs. **Deux plafonds sur la base** : 10 🍑 par course (`MAX_BALLS_PER_RUN`) et 10 🍑 par
jour et par participation (`MAX_BALLS_PER_DAY`, mémorisé dans `trainings.base_balls`) — couper
une sortie de 20 km en deux ne rapporte rien de plus, ni en boules ni en ligue.
Les 🍑 sont **créditées à l'import** (`Training#credit_balls!`, idempotent) ; les courses sont
jugées automatiquement (voir « Contrôle des courses importées »), `Training.scoring` = verified
+ protected.
**Porte-monnaie plafonné à 100 🍑** (retour v1, `GameRules::WALLET_CAP`) : le crédit est tronqué
au plafond, l'excédent est perdu (notif importante « dépense tes boules ! ») — mais le **score de
la course reste entier**, donc la ligue n'est jamais pénalisée. Avec l'échec critique (15 % du
solde), thésauriser est doublement puni.

## Modèle de données (22 tables — voir db/schema.rb)

Séparation clé : **Event** (la course réelle, ex. Odyssea 2027) → **Game/partie** →
**Membership** (un user dans une partie, dans une équipe). Un user joue plusieurs parties ;
ses 🍑/streak/courses **et son fruit-avatar** (`memberships.fruit`) sont **par partie**, ses
cosmétiques/💎 sont **globaux**.

- **Compte** : `User`, `Avatar`, `Cosmetic`, `UserCosmetic`, `PushSubscription`, `Notification`
- **Partie** : `Event`, `Game`, `Team`, `Monster` (PV + `wear`), `TeamEffect` (vent/saladier), `SpecialDay`
- **Participation** : `Membership`, `Training` (course Strava scorée)
- **Combat/éco** : `Item`, `MembershipItem`, `Action` (attaque/soin/objet, cible polymorphe),
  `Chest` (coffre), `Reward` (registre des gains)
- **Social** : `Conversation` (kind `general` = toute la partie, ou `team` = privé équipe), `Message`,
  `ConversationRead` (dernière lecture d'une conversation par participation → pastille non lus)

## Ce qui est déjà construit (commits)

1. Scaffold Rails 8 + Inertia + React + Vite + Tailwind (SQLite)
2. Les 21 modèles + migration + seed de démo (partie jouable)
3. **Sync Strava** (scorer 1km=1🍑 plafond 10 × jour spécial ; d'abord polling, puis webhooks)
4. **Auth** email/mdp + **Google** ; écrans **Login / Register / Hub**
5. **Combat** (service `PerformAction` : attaque/soin/objet, PV, saladier, vent), **Chat**
   (partie + équipe), **Notifications + Web Push** (VAPID, service worker)
6. **Strava temps réel** : Webhook Events API (`/strava/webhook` verify + event), OAuth connect,
   refresh de token, job d'import ; reconciliation quotidienne en filet de sécurité
7. **Classement** (`/ligue`) : deux classements, mensuel et général, récompense au 1er du mois
8. **Avatar** (`/avatar`) : personnalisation + équipement des cosmétiques possédés
9. **Mécaniques de saison** (voir section dédiée) : jauge de meute, monstre affamé, second
   souffle, vent de face, chantilly, résolution des pièges au scoring, fin de partie

### Mécaniques de saison (calibrées sur les données v1 — voir `GameRules`)

La saison type dure ~24 semaines (1er oct → 15 mars). L'équilibrage vient de l'analyse du dump
v1 : ~165 🍑/semaine pour 15 actifs, et une partie morte à mi-saison à cause d'un multiplicateur
permanent achetable (les « Vitamines ») — d'où les garde-fous ci-dessous.

- **🐾 Jauge de meute** (`PackLevelJob`, le lundi) : semaine où **≥ 5 coéquipiers ont couru
  ≥ 10 km chacun** → `teams.pack_level += 1`, soit **+10 % permanents** sur attaques ET soins.
  **Additif, plafond ×2** (10 paliers), jamais multiplicatif, jamais achetable.
  `Team#combat_multiplier` remplace l'ancienne colonne `teams.multiplier` (supprimée).
- **🍽️ Monstre affamé** (`FamineJob`, quotidien) : équipe sans course depuis **72h** → son
  monstre perd **50 PV/jour**, plancher à **5 %** des PV max (la famine ne tue pas, le coup
  final reste aux joueurs). Chip d'avertissement 🍽️ sur le Hub dès 48h (`TeamEffectsPresenter`).
- **💨 Second souffle** : premier passage d'un monstre **sous 25 %** → soins de son équipe à
  **1 🍑 pendant 7 jours**, une fois par partie (`teams.second_wind_until`, déclenché dans
  `Monster#refresh_state!`).
- **🏁 Fin de partie** (`FinishGame`) : monstre à 0 (via une attaque) OU `ends_at` atteint
  (via `FamineJob`) → `games.status = "finished"`, `winner_team_id` (nil = égalité au % de PV),
  notification à tous, bannière sur le Hub, combat verrouillé (garde dans `PerformAction`).
- **🐺 Résolution des pièges** (`ResolveRunEffects`, appelé à l'import) : le piège non résolu
  le plus ancien visant le coureur se referme → course `trapped`, 0 🍑 — sauf jambe de bois
  armée → course `protected`, 🍑 sauvées. Les `Action` concernées sont marquées `resolved_at`
  (usage unique). Notifications importantes aux deux camps.
- **🌬️/🌪️ Vents sur les courses** : appliqués par `TrainingScorer` à la **date réelle** de la
  course (une course importée en retard est bien jugée) — dos ×1,5 / face ×0,75, 12h.
- **🍦 Chantilly** (ex-Fumigène ; `effect_type`/`TeamEffect kind` restent `"smoke"`) : 24h.
  L'**équipe adverse est toujours aveuglée** (colonne `team_id`) ; le poseur choisit **quel
  monstre** lui masquer — le sien ou celui de l'adversaire (`team_effects.masked_team_id`,
  sélecteur `MonsterPicker`, param `target_team` `mine`/`foe`). `Team#smoke_masks?(monster_team_id)`
  → `MonsterPresenter` masque **ce monstre** (hp/max_hp/percent nil, `masked: true`) pour l'équipe
  visée sur Hub et Combat, et le front lui colle de la **chantilly dans les yeux** (`creamed`) :
  même condition que les « ??? », donc seule l'équipe aveuglée voit le monstre barbouillé.
  L'autre monstre et le dessin restent visibles. Le chip 🍦 indique « <monstre> masqué ».
- **🥣 Saladier** (ex-Bouclier ; `effect_type` reste `"shield"`) : `monster.protected_until` 6h,
  intouchable. Le front (`protected`) pose un **saladier translucide retourné** par-dessus le
  monstre — visible de tous, sur le Hub comme en Combat.
- **🎉 Journées spéciales** : 5-6 par saison (`SpecialDay`, ×2). Seedées : Halloween 31/10 et
  Réveillon 24/12. Le multiplicateur s'applique après le plafond → plafond effectif doublé.
- **🔥 Streak hebdo** (`WeeklyStreakJob`, le lundi) : ≥ 1 course scorée dans la semaine →
  série +1 et 💎 selon l'échelle 10/20/30/40/50 (plateau 50). **Tous les 5 paliers** :
  cosmétique tiré au sort (fallback 100 💎) + **1 joker** 🧊 (max 2, jamais achetable).
  Semaine ratée : un joker se consomme et **gèle** la série, sinon retour à zéro.
  Doublement idempotent (`memberships.last_streak_week` + registre `rewards` source
  `streak`/`streak_gift`). ~1 100 💎 max par saison parfaite → **prix boutique calés
  dessus : common ~100 · rare ~250 · epic ~500 · legendary 1000**. Notifs importantes
  (gain, gel, perte), jokers visibles sur la tuile 🔥 du Hub.
- **🎁 Coffres** (`DropChest`, appelé à l'import après le crédit) : une course scorée a
  15 % de chance de cacher un coffre — **max 1/jour** par participation, **pity** garanti
  après 7 courses scorées sans drop. Rareté pondérée (60/25/12/3), contenu décidé **au drop**
  (💎 15/30/60/120 + parfois un cosmétique non possédé, toujours pour un légendaire — c'est
  par là qu'arrive l'Esprit du loup). Ouverture sur le **Hub** (`ChestCard`) en **modal
  plein écran** : coffre SVG qui tremble → POST → au rechargement, `flash[:chest]` rouvre la
  modal en mode révélation (couvercle sur charnière, **paillettes**, gains qui sortent en
  chips). Pas de tuile « coffres » : la carte n'apparaît que s'il y a un coffre scellé.
  `Chest#open!` idempotent (verrou + statut) crédite et journalise dans `rewards`
  (period `chest-<id>`), doublon acquis entre-temps → +30 💎.
- **💥 Échec critique** (retour v1) : 1 attaque sur 10 rate (`PerformAction#crit_fail`) — 0 dégât
  et perte de **15 % du solde** (min 1, max 10 🍑), non multipliée par la meute. Taxe les
  thésauriseurs (pas de plafond de porte-monnaie en v2) sans inverser l'économie attaque/soin
  (coût moyen d'une attaque ~1,1 🍑 pour un actif). Flash rouge + notifs « morsure » aux deux camps.

### Contrôle des courses importées (anti-triche)
**Aucune validation humaine** : `TrainingPolicy` (app/services) juge chaque course à l'import et
tranche seul — elle compte, ou elle est **rejetée** avec une raison lisible par le joueur
(`trainings.rejection_reason`). Une course rejetée est **conservée mais inerte** : 0 🍑, aucun
piège consommé, aucun coffre, absente du feed public ; seul le coureur reçoit une notif
importante avec la raison, et la sortie affiche le motif sur son profil et sa page.

Tous les seuils sont dans `GameRules` (bloc anti-triche). Les contrôles, dans l'ordre :
1. **Nature** — `sport_type` dans `ALLOWED_SPORT_TYPES` (Run/TrailRun/VirtualRun/Treadmill —
   on lit `sport_type`, pas `type` qui range TrailRun et VirtualRun sous « Run ») ;
   `manual` (saisie à la main) et `flagged` (signalée par Strava) refusés.
2. **Preuve d'effort sur tapis** — course **sans tracé GPS** : il faut la fréquence cardiaque
   (`HEARTRATE_RANGE`) **ou** au moins une photo. Le contrôle est automatique (« il y a une
   photo »), la dissuasion est **sociale** : la photo est visible de tous sur la sortie.
3. **Effort plausible** — 2 à 80 km, allure entre **3:00 et 9:30 /km** (sur `moving_time`),
   durée obligatoire.
4. **Fenêtre** — pas plus de 7 jours (`IMPORT_WINDOW`), pas dans le futur (+1 h de tolérance),
   dans la période de la partie. Connecter Strava en cours de saison ne déverse pas l'historique.
5. **Unicité** — activité déjà importée par **un autre joueur** refusée (le même joueur peut la
   faire compter dans plusieurs parties) ; **doublon montre + téléphone** : deux sorties qui se
   recouvrent, c'est la plus longue qui reste (`ImportTraining#supersede_shorter_duplicates`).
   Index unique sur `users.strava_uid` : un athlète Strava = un joueur.

**Cycle de vie complet** (`Strava::WebhooksController`) : `create`/`update` → `ImportTraining`
(re-juge tout : sport corrigé = la course sort, photo ajoutée = elle entre et crédite),
`delete` → `StravaActivityRevokeJob`. `RevokeTraining` reprend les 🍑 réellement versées
(`trainings.credited_balls`, plancher à 0 — jamais de solde négatif), efface le score,
supprime un coffre encore scellé et **réarme le piège à loup** que la course avait fait claquer
(`actions.resolved_training_id`) — sinon il suffirait de publier une vraie sortie, de la
supprimer, puis de courir. `StravaSyncJob` sert de filet dans les deux sens : il réimporte les
courses récentes et **retire** celles que Strava n'a plus (sauf si l'appel API a échoué).

Côté joueur : l'**allure est affichée partout** (liste des sorties, feed de notifs, page de la
sortie), un chip **quota du jour** apparaît sur le Hub dès qu'on a couru, la page d'une sortie
explique le plafond journalier atteint, et la FAQ a une section « ✅ Quelles courses comptent ? »
(en français courant, sans jargon technique). ⚠️ `config.time_zone = "Europe/Paris"` : le quota
journalier et les jours spéciaux tombent sur le bon jour.

### Les classements (`/ligue`)
Un classement par partie, les deux clans mélangés, **pas de divisions** (elles ont existé une
journée puis ont été retirées — ne pas les réintroduire sans demander). Deux périodes :

- **Du mois** : du 1er au dernier jour du mois en cours.
- **Général** : depuis `game.starts_at`.

Le score est la somme des 🍑 des `Training` vérifiés de la période. Il n'est **pas stocké** :
`LeagueStandings` le recalcule, donc le classement du mois repart de zéro tout seul le 1er —
rien à remettre à zéro en base. Seule la récompense est persistée.

**Récompense du mois** : le 1er gagne un cosmétique tiré au hasard parmi ceux qu'il ne possède
pas encore (`AwardMonthlyLeague`). S'il les possède tous, il touche 100 💎 à la place —
sinon il n'y aurait rien à donner. Personne n'est récompensé si personne n'a couru.
`LeagueMonthlyRewardJob` tourne le 1er de chaque mois et juge le mois **écoulé**.

L'opération est **idempotente** : la récompense est écrite dans `rewards` avec la période
(`period: "2026-07"`) sous index unique `[membership_id, source, period]`. Rejouer un mois,
ou lancer le job en retard, ne décerne jamais le titre deux fois.

### L'avatar (`/avatar`) — fruits par équipe
L'avatar = un **fruit** (choisi une fois affecté à une équipe) sur lequel se posent les
cosmétiques équipés. **Portée par participation** : `memberships.fruit`, donc un joueur peut être
Ananas dans une partie et Fraise dans une autre. On ne peut le personnaliser **qu'en équipe**
(l'écran affiche un message tant qu'on n'a pas de `Membership`).

- `FruitCatalog` (app/models) = source de vérité : deux familles (`exotiques` / `rouges`), chacune
  une liste de fruits `{ key, name }`. `teams.fruit_family` fixe la famille d'une équipe.
- La **clé** du fruit est partagée avec le front : `components/FruitAvatar.jsx` dessine chaque
  fruit en **SVG** (silhouette + visage commun, pas d'assets). Toute clé ajoutée dans le
  catalogue Ruby doit avoir son pendant visuel dans `components/fruits.js`.
- Choix **partageable** : plusieurs coéquipiers peuvent prendre le même fruit ; l'écran indique
  « déjà : X » sous chaque fruit. Le fruit doit appartenir à la famille de l'équipe (validé).

**Les 7 emplacements** (`Cosmetic::SLOTS`) — l'avatar est une **tête** de fruit, donc **ni tenue
ni jambes** : `hat` chapeau · `eyes` lunettes · `neck` nœud pap'/cravate/écharpe/collier ·
`hands` **bras** (gants, bras mécanique, baguette — un de chaque côté, le droit en miroir ;
libellé joueur « Bras », clé `hands`) · `shoes` paire de chaussures sous le fruit ·
`sidekick` accessoire posé à côté (animal, gourde, barre…) · `aura` halo en fond.
Un seul cosmétique par slot ; `cosmetics.emoji` est ce qui les rend affichables.

**Deux références, jamais des ancres fixes.** Tout ce qui touche au visage se cale sur la
**ligne des yeux** (`EYE_LINE = 52`, commune à tous les fruits) : lunettes dessus, gants juste
en dessous. Le reste suit la **silhouette**, déclarée par chaque fruit dans `components/fruits.js`
via `box` — `top` (ligne du crâne), `bottom` (ligne du sol), `half` (demi-largeur), `hatX`
optionnel : le chapeau se pose sur le sommet **réel** (banane, carambole, ananas compris), les
chaussures sous la vraie base, les gants à la vraie largeur (jamais sur les joues, grâce à un
plancher). `FruitAvatar#anchors()` en déduit les positions et chaque pièce est **centrée** sur
son point. Les pièces restent **serrées autour du fruit** : une pièce qui s'éloigne fait paraître
l'avatar plus petit dans un cadre de taille fixe.

⚠️ **Un glyphe emoji pend sous le centre de sa boîte de ligne** : recentrer la boîte posait donc
toutes les pièces trop bas (lunettes sous les yeux, gants au menton). La classe `.fav-glyph`
remonte le glyphe de `.115em` de sa propre taille ; les dessins SVG, déjà centrés dans leur
viewBox, n'y touchent pas.

L'**aura** est une couronne de 6 petits emojis **derrière** le fruit (`z-index` 0 < `.fav-svg`),
assez rapprochée (rayon 33) pour que la silhouette en masque une partie, et translucide (`.5`) —
un seul gros emoji avalait l'avatar, une couronne trop large flottait à côté au lieu d'être
derrière. Sous **44 px** (chat, ligue, listes) seuls aura/lunettes/chapeau sont rendus — sinon
c'est une bouillie d'emojis.
**Emoji par défaut, SVG quand l'emoji ne peut pas** (`cosmetics.art` → `components/cosmeticArt.jsx`) :
trois familles d'emojis ne marchent pas sur un avatar-fruit —
1. les **chaussures** (👟 🥾 🛼 sont des godasses *uniques* vues de *profil*, on veut une paire de face) ;
2. les **visages entiers** (🤠 🧐 🎅 colleraient une deuxième tête sur celle du fruit) ;
3. les **emojis déjà pairs dans un slot symétrique** — 🧤 est une paire de gants, reflété de chaque
   côté il donnait **quatre mains** (d'où le dessin `mitten`, une seule moufle).

Ces pièces portent une clé `art` et sont dessinées à plat : `sneakers`/`trail`/`ballet`/`skates`/
`boots7` (les 5 paires de chaussures), `mitten`, `paw`, `gold_hat` (🎩 est noir et bleu, le nom
promettait de l'or), `cowboy_hat`, `santa_hat`, `bucket_hat`, `monocle`, `eyepatch`, `visor`,
`bowtie`, `bib`, `bandana`.

Trois drapeaux de mise en page, sur l'entrée `COSMETIC_ART` :
- **`pair: true`** — le dessin contient déjà les deux pièces (chaussures) → jamais dupliqué, et
  le slot `shoes` lui donne sa propre ancre (`at.art`, plus large qu'un emoji) ;
- **`single: true`** — la pièce ne se porte que d'un côté (la baguette magique) ;
- sans drapeau, la pièce est posée **de chaque côté, la droite en miroir** : elle doit donc
  représenter **UN** bras. C'est la règle que violaient 🧤 et 🐾 (déjà des paires → quatre mains).

Une entrée peut porter **`emoji` au lieu de `node`** : le glyphe est rendu tel quel, mais avec
les drapeaux ci-dessus — c'est ainsi qu'on dit « cet emoji ne se duplique pas » sans le dessiner.
`CosmeticIcon` (même fichier) sert la vignette dans l'armoire et la boutique. Le reste du
catalogue reste en emoji, et le sera par défaut.

- **Catalogue : 69 pièces** (dont 7 de saison) dans le seed (tous les slots garnis, grille 100/250/500/1000) dont 7
  **exclusives** `price_diamonds: nil` (sources `event`/`rank`/`drop` : Noël, Halloween, médaille,
  loup…) — jamais en vente, mais **tirables** par les cadeaux de streak et de ligue (comportement
  assumé, comme la Couronne). Ajouter une pièce = une ligne dans le seed (slot existant + emoji),
  aucun code — sauf si elle a besoin d'un dessin, alors + une entrée dans `COSMETIC_ART`.
  Ajouter un **slot** = une entrée dans `anchors()` + un z-index CSS `.fav-<slot>`.
- **L'écran est un vestiaire, pas une liste** : l'aperçu de l'avatar et la barre d'emplacements
  restent **collés en haut** (`.av-sticky`) pendant qu'on fouille — on juge le rendu sans faire
  l'aller-retour. Un onglet par emplacement (+ « Fruit »), une pastille verte quand quelque
  chose y est équipé, et le rayon n'affiche **que** les pièces de l'emplacement choisi, avec une
  case « Retirer » quand on porte quelque chose. Empiler tout le catalogue d'un coup obligeait à
  scroller entre la pièce et l'avatar.
- Le seed crée **`vitrine@btb.test`**, un compte qui **possède les 69 pièces** (et ne court pas,
  donc ne fausse ni la ligue ni la meute) : `/avatar` liste tout le catalogue, slot par slot,
  pour juger le rendu d'un coup d'œil.

Cet écran fait aussi office de **compte** (accès en tapant l'avatar du Hud) : **connecter/déconnecter
Strava** (`StravaController#connect` / `#disconnect`, prop `strava_connected`) et **se déconnecter**
(`DELETE /logout`). Les deux boutons de suppression demandent une confirmation.

`AvatarPresenter.new(user, membership:)` est le **seul** endroit qui sérialise un avatar (fruit +
cosmétiques), affiché dans le Hub, le chat, le classement et l'écran avatar. Côté React, le
composant unique est `components/PlayerAvatar.jsx` (délègue à `FruitAvatar`, pastille + initiale
en secours si pas de fruit).

### Les monstres
Dessinés en SVG dans `components/Monster.jsx`, choisis par `Monster#slug` (`"King-Coco"` →
`king-coco`). King-Coco (roi noix de coco) et Framboitrix (sorcière-framboise, clin d'œil à
Bellatrix Lestrange) pour Odyssea. Un slug inconnu retombe sur un emoji 👾.

**Le dessin évolue**, piloté par trois props que sert `MonsterPresenter` :
- **`wear` 0→3 — l'usure** : à chaque **premier** passage sous **75 / 50 / 25 %** des PV, le
  monstre prend un cran (`monsters.wear`, calculé dans `Monster#refresh_state!` via
  `GameRules::MONSTER_WEAR_THRESHOLDS`). **Cliquet** : `wear` ne redescend jamais — un soin
  remonte les PV, pas la façade, et la barre de vie reste la seule info exacte. King-Coco se
  fend (chair blanche visible), sa couronne glisse et perd ses pierres, ses yeux passent
  mi-clos puis en croix ; Framboitrix perd ses drupéoles (elles roulent à ses pieds), sa
  crinière retombe, son chapeau se déchire et ses yeux partent en vrille. Pansement et goutte
  de sueur communs. Au-delà du 2e palier, le monstre **tangue** (`.mon.wear2/.wear3`, guard
  `prefers-reduced-motion`).
- **`creamed`** : chantilly plein les yeux tant que l'effet dure (= `masked`, donc pour la seule
  équipe aveuglée, celle qui voit « ??? »).
- **`shielded`** : saladier translucide retourné (= `protected`), le monstre se tasse dessous. En **Combat**, l'attaque secoue + flashe en rouge le monstre
adverse (💥 + « -N ») et le soin fait gonfler mon monstre avec une lueur verte (✨ + « +N »),
piloté par état React dans `pages/Combat.jsx` (classes `.impact` / `.healpulse`, guard
`prefers-reduced-motion`).

### Le compte à rebours (Hub)
En haut du Hub, `components/Countdown.jsx` décompte jours/heures/min/sec jusqu'au **jour J**.
La date vient de l'`Event` (`events.race_date`, un `datetime`) — Odyssea Nantes est le
**21 mars 2027 à 9h** dans le seed. Le Hub sérialise
`event: { name, location, race_at (ISO), starts_at (ISO) }` et le composant tique chaque seconde
(`setInterval`), puis affiche « C'est le grand jour ! » une fois la date passée. Piloté par la
donnée : changer `race_date` déplace le décompte.

Sous le décompte, une **barre de progression** « vers l'arrivée » : un coureur 🏃 avance vers un
drapeau 🏁, rempli de `game.starts_at` (ligne de départ) à `race_at` (arrivée), avec le % du
parcours. Calculée côté React à partir des deux timestamps.

### Profils & sorties (`/joueurs/:id`, `/courses/:id`)
Chaque **participation** (Membership) a une page profil consultable par **tout joueur de la même
partie** (les deux clans — `ApplicationController#shares_game?`). Elle liste ses sorties (date,
heure, km, 🍑, statut) et lie vers le détail de chacune.

Le **détail d'une sortie** (`/courses/:id`) montre ce qu'on récupère de Strava : titre,
description, durée, allure, dénivelé, **tracé du parcours** et photo. Les champs sont stockés sur
`trainings` (`title`, `description`, `moving_time`, `elapsed_time`, `elevation_gain`,
`route_points`, `photo_url`) et remplis à l'import (`StravaActivityImportJob`).

- Le **tracé** est affiché sur un **vrai fond de carte** (`components/RouteMap.jsx` : **Leaflet**
  + tuiles **OpenStreetMap**, comme la v1) à partir de `route_points` (`[[lat, lng], …]`). Les
  tuiles OSM sont gratuites (attribution obligatoire, incluse) — compatible objectif ~5-6 €/mois.
  La polyline Strava est décodée à l'import par le module `Polyline`. `.route-map` garde
  `z-index: 0` pour que les contrôles Leaflet passent sous la nav.
- `TrainingPresenter` sérialise une sortie (résumé pour la liste, détail pour la page) — seul
  endroit qui formate dates, durées et allure.
- Les **noms sont cliquables** vers le profil dans le chat et la ligue (et l'avatar au chat).

### La boutique (`/boutique`)
Deux monnaies **étanches** (règle d'or, jamais de pay-to-win), servies par le service `Purchase` :
- **Objets** (power-ups) en 🍑 boules (`Membership.balls`, par partie) → déposés dans l'inventaire
  de la participation (`MembershipItem`, `used: false`). **À usage unique** : « Utiliser » réutilise
  `PerformAction` (`use_item`) et consomme l'objet. Catalogue (prix calibrés sur ~10 🍑/sem
  pour un actif médian) : **Jambe de bois 4** · **Vent de dos 4** · **Vent de face 4** ·
  **Chantilly 4** · **Piège à loup 5** · **Saladier 6** (6h). Le vent de face notifie ses
  victimes nominativement (agressivité assumée) ; la chantilly aveugle toujours l'adversaire et
  choisit quel monstre barbouiller. ⚠️ Seuls les **libellés** ont changé (ex-Fumigène /
  ex-Bouclier) : les `effect_type` restent `smoke` et `shield` dans tout le code.
- **Cosmétiques** en 💎 diamants (`User.diamonds`, global) → déposés dans l'armoire
  (`UserCosmetic`). On les **équipe / remet dans l'armoire** depuis l'écran avatar (`/avatar`).
  Seuls les cosmétiques `price_diamonds` non nul sont en vente (les récompenses ne le sont pas).

**✨ Boutique de saison** (`cosmetics.available_from` / `available_until`, les deux facultatifs) :
une pièce peut n'exister qu'un temps. `Cosmetic.available(at)` est **la** porte d'entrée — hors
fenêtre, la pièce disparaît de la boutique **et des tirages** (coffre, streak, ligue : un bonnet
de Noël ne doit pas tomber en juillet), et `Purchase.cosmetic` la refuse même si l'id est posté
à la main. Ce qui est **déjà acheté reste acquis pour toujours** : l'armoire ignore la fenêtre.
Le rayon est servi à part (`seasonal` vs `cosmetics` dans `ShopController`) : les pièces qui ont
une date de fin s'affichent dans un encadré violet en tête de l'onglet Cosmétiques, chacune avec
son compte à rebours (« Encore 12 jours », « Dernier jour ! »). Ouvrir une collection = poser
deux dates sur des lignes du seed, aucun code.

Trois onglets : Objets · Cosmétiques · Sac (inventaire des objets + lien vers l'armoire). Les
achats sont refusés proprement si monnaie insuffisante, cosmétique déjà possédé, ou pas d'équipe.

### Notifications — deux niveaux (`notifications.importance`)
- **important** : poussé en Web Push **et** listé. Concerne le joueur directement — message dans
  la **conversation d'équipe**, récompense (coffre, ligue, streak), « ma course a été piégée /
  mon piège a réussi / mon piège a été déjoué », vent de face ou chantilly **reçue**, palier de
  meute gagné, monstre affamé, second souffle, fin de partie.
- **secondary** (défaut) : **listé seulement**, jamais poussé. L'activité des autres — « X a
  couru N km · +N 🍑 » (km **et** boules gagnées), « X a activé un vent de dos jusqu'à… », « X a
  posé un piège à loup », et le **combat** : attaque (⚡ « -N PV ») et soin (💚 « +N PV »), avec
  les PV en jeu. `PerformAction#broadcast_combat` notifie **tout le monde, l'auteur inclus** :
  l'auteur reçoit une version à la 1re personne (« Tu as infligé… »), les autres la 3e (« X a
  infligé… ») — pour qu'on voie sa propre action dans ses notifications.

Le **chat général ne crée AUCUNE notification** (seul le chat d'équipe notifie, en important) :
`MessagesController#notify_participants` sort tôt si `conv.kind != "team"`. Les messages non lus
du chat se voient sur la **pastille de l'onglet Chat** (voir ci-dessous), pas dans la liste.

Le push n'est déclenché que pour les importantes (`Notification#push_if_important`).
`Notification.broadcast(users, importance:, …)` crée la même notif pour plusieurs destinataires.
L'écran Notifications sépare **Pour toi** (importantes) et **Activité de la partie** (secondaires,
style atténué). Une notif peut porter un **`link`** (colonne `notifications.link`) : la carte
devient alors cliquable (chevron ›). Les notifs « nouvelle course » pointent vers `/courses/:id`.

### Pastille de messages non lus (onglet Chat)
`conversation_reads` (`membership` × `conversation` × `last_read_at`, index unique) mémorise la
dernière lecture. `Membership#unread_messages_count` compte les messages **des autres** (équipe +
général) postés après `last_read_at`, exposé globalement via `chat_unread` (`inertia_share`) et
affiché en pastille sur l'onglet **Chat** (`components/BottomNav.jsx`). Ouvrir le chat
(`ChatController#show`) appelle `Membership#mark_conversations_read!` → la pastille retombe à 0.
⚠️ Le seed doit vider `ConversationRead` en tête du nettoyage (FK vers membership/conversation).

### Profil : pas de solde de 🍑
La réserve de boules d'un joueur ne se voit **que sur sa propre page d'accueil** (le HUD), jamais
sur la page profil d'un joueur.

### Effets d'objets (combat)
`PerformAction` (`use_item`) applique les effets. **Les effets à durée sont publics** :
`TeamEffectsPresenter` liste, pour une équipe, ses `TeamEffect` actifs (vent de dos/de face) +
le saladier du monstre (`monster.protected_until`), chacun avec son échéance. Affichés par
`components/EffectBadges.jsx` sur le **Hub** (les deux clans) et en **Combat**.

- **Piège à loup** (`trap`) : on **choisit un adversaire** (`components/TargetPicker.jsx`, dans le
  Combat et le Sac) ; la cible est enregistrée dans l'`Action` mais l'annonce publique reste
  **générique** — « X a posé un piège à loup » notifiée à tous les autres joueurs, personne ne
  voit qui est visé.
- **Jambe de bois** (`wooden_leg`) : usage **silencieux** (rien n'est annoncé) ; elle ne se
  révélera dans les notifications qu'au moment où elle déjouera un piège.
- Les effets sur les courses sont **résolus à l'import** : pièges/jambes par
  `ResolveRunEffects`, vents par `TrainingScorer` (voir « Mécaniques de saison »).

### La FAQ / règles (`/faq`)
Page **statique** des règles du jeu (`FaqController#show` → `pages/Faq.jsx`), en sections
repliables (`<details>`) : but, boules, combat, objets, diamants, ligue, avatar, notifications,
+ un encadré « règle d'or ». **Aucun prop** : tout le contenu vit dans le tableau `SECTIONS` du
composant — c'est le seul endroit qui décrit le fonctionnement côté joueur, **à mettre à jour
quand une mécanique change**. Lien 📖 dans le **header du Hud** (à côté de la cloche 🔔).

### Écrans React existants (app/frontend/pages)
`Hub`, `Combat`, `Chat`, `Ligue`, `Avatar`, `Boutique`, `Profile`, `Training`, `Notifications`,
`Faq`, `Admin`, `auth/Login`, `auth/Register`.
Navigation par onglets : **Hub · Chat · ⚔️ Combat · Ligue · Boutique** (`components/BottomNav.jsx`),
tous actifs.

### PWA (installable)
`PwaController` (maison) sert `/manifest.json` et `/service-worker` — **pas**
`Rails::PwaController` : il rate le format du template `.js` (la requête d'enregistrement
arrive en `Accept: */*` → MissingTemplate 500), d'où `formats:` explicites +
`skip_forgery_protection` (l'anti-JSONP refuse de rendre du .js non-XHR, 422). Le template
est `app/views/pwa/service-worker.js` (**avec tiret** — le nom que Rails cherche) : push
Web (VAPID) + clic → ouvre l'app. Icône 🍑 flat : `public/icon.svg` (source) et `icon.png`
512 (généré). Manifest aux couleurs de la charte (`#ff7a59`), `display: standalone`.
`components/InstallHint.jsx` sur le Hub : guide iOS (Partager → écran d'accueil, requis pour
recevoir les push sur iPhone) ou bouton natif `beforeinstallprompt` ailleurs, refus mémorisé
en localStorage.

### Pièges connus
- **`form.transform()` de `@inertiajs/react` ne retourne rien** (v3.6.1) : `form.transform(fn).post(…)`
  lève un TypeError et le formulaire ne part jamais, sans erreur visible. Appeler `transform`
  puis `post` sur deux lignes. C'est ce qui cassait l'envoi de messages dans le chat.
- Créer un nouveau dossier sous `app/` (ex. `app/presenters`) demande un **redémarrage** du
  serveur : il n'est pas ajouté aux chemins d'autoload à chaud.
- Après une migration, redémarrer aussi : Puma garde en cache la liste des colonnes.

## Design

**Flat design** (aplats de couleur, pas d'effets 3D). Tokens CSS dans
`app/frontend/entrypoints/application.css` (thème clair + sombre auto) :
🍑 pêche `--peach`, 🍋 citron `--citron`, 🍓 fraise `--fraise`, 💎/saison `--violet`,
menthe action `--mint`. Rareté cosmétiques : common/rare/epic/legendary.
Mobile-first, `.shell` centré max 460px. Stats en `font-variant-numeric: tabular-nums`.

Maquettes de référence (privées, pour l'humain — Claude ne peut pas les ouvrir) :
- Écrans flat v2 : https://claude.ai/code/artifact/08cc4efd-1ce2-48cc-bd30-f50a18a85242
- Schéma BDD : https://claude.ai/code/artifact/3711a673-bfcb-4368-a42d-27b3a0ea751e
- Plan de démarrage : https://claude.ai/code/artifact/cb6fd930-ef35-4163-8164-a8e48dff3238

### Back-office de l'organisateur (`/admin`)
Réservé au joueur dont la participation est `role: "admin"` (`Membership#admin?`) ; un autre
joueur est renvoyé à l'accueil, et le lien n'apparaît que pour lui, en bas de l'écran compte.
Il ne couvre **que les deux réglages qui se pilotent par des dates** et qu'on veut changer sans
redéployer : les **journées ×2** (ajout/suppression) et les **fenêtres de la boutique de saison**
(deux champs date par cosmétique, vides = pièce permanente). Une borne de fin court jusqu'au
**bout de sa journée**, sinon la pièce expirerait à minuit pile. Le reste du contenu (créer une
partie, des équipes) reste au seed.

Les mêmes réglages en ligne de commande, pour le jour où on est en SSH (`lib/tasks/season.rake`) :
```bash
bin/rails season:show                                              # état des lieux
NAME=Halloween DATE=2026-10-31 bin/rails season:special_day        # journée ×2
NAMES='Parasol,Tournesol' FROM=2026-07-01 UNTIL=2026-08-31 bin/rails season:open
NAMES='Parasol' bin/rails season:close                             # redevient permanent
```

## Roadmap (à faire, ordre suggéré)

1. **Admin de partie** — créer Event/Game/Teams depuis l'app (l'écran `/admin` existe déjà pour
   les journées spéciales et la boutique de saison ; la validation manuelle des courses n'existe
   pas : le contrôle anti-triche est 100 % automatique, voir la section dédiée).
2. **Rejoindre une partie depuis l'app** — aujourd'hui un `Membership` se crée encore à la main
   en console, il n'y a pas d'écran pour rejoindre une équipe.
3. **Déploiement** (Kamal, VPS) — y ajouter le **mot de passe oublié** (nécessite un SMTP,
   ex. Brevo comme la v1) et une limitation des tentatives de connexion (rack-attack).

## Commandes utiles

```bash
bin/dev                 # Rails + Vite → http://localhost:3000
bin/rails db:prepare    # crée + migre + seed
bin/rails console
bin/rails webpush:keys              # génère les clés VAPID
CALLBACK_URL=https://.../strava/webhook bin/rails strava:subscribe  # abonnement webhook (prod)

bin/rails league:standings          # classements du mois et général, en console
bin/rails runner PackLevelJob.perform_now   # juge la semaine écoulée (jauge de meute)
bin/rails runner FamineJob.perform_now      # famine + clôture de saison (quotidien en prod)
MONTH=2026-06 bin/rails league:award_month         # décerne la récompense d'un mois (test)

bin/rails season:show                              # journées ×2 + fenêtres de la boutique
NAME=Halloween DATE=2026-10-31 bin/rails season:special_day
NAMES='Parasol,Tournesol' FROM=2026-07-01 UNTIL=2026-08-31 bin/rails season:open
```

⚠️ **Vite 8 exige Node ≥ 20.12** (`node:util#styleText`). Node 16 fait planter `bin/dev` avec
`SyntaxError: … does not provide an export named 'styleText'` — `nvm use 22` avant de lancer.

### En développement sous Windows (natif, sans WSL)

**Pour lancer le serveur sous Windows : `.\bin\dev.ps1`** (et rien d'autre — voir pourquoi juste
en dessous). Le jeu répond alors sur http://localhost:3000, connexion `yann@btb.test` /
`odyssea2027`.

`bin/dev` est un script `sh` qui passe par **foreman** : ni l'un ni l'autre ne tourne en natif
sous Windows. Les scripts `bin/*` n'ont pas non plus de bit exécutable — on les appelle donc
par l'interpréteur. `bin/dev` reste le chemin normal sous Linux/macOS ; les deux coexistent.

```powershell
.\bin\dev.ps1               # Rails + Vite dans CE terminal, Ctrl+C arrête les deux
.\bin\dev.ps1 -Stop         # arrête les serveurs et rend la main
.\bin\dev.ps1 -NewWindows   # une fenêtre par process, si on préfère séparer les logs
ruby bin\rails db:prepare   # tout bin/rails s'appelle "ruby bin\rails …"
ruby bin\rails console
```

**Relancer, c'est juste relancer** : le script libère les ports 3000/3036 avant de démarrer.
Il retrouve les serveurs de deux façons, parce qu'aucune ne suffit seule — par le process qui
écoute le port (le node enfant de Vite, son parent ruby n'écoute rien) et par la ligne de
commande (`bin/rails`, `bin/vite`). Il ne tue que du ruby ou du node, jamais un process tiers
qui aurait pris le 3000. C'est ce qui permet d'arrêter un serveur lancé depuis un autre
terminal, ou par un agent, sans avoir de `Ctrl+C` sous la main.

Quatre pièges, tous déjà réglés dans ce dépôt mais à refaire sur une machine neuve :

1. **Bundler 4** — le `Gemfile.lock` est en `BUNDLED WITH 4.0.9`, RubyInstaller livre 2.5.x :
   `gem install bundler -v 4.0.9`.
2. **Plateforme absente du lock** — le `Gemfile.lock` ne listait que linux/darwin, `bundle install`
   refusait de tourner : `bundle lock --add-platform x64-mingw-ucrt` (sqlite3, nokogiri, ffi et
   bcrypt_pbkdf ont alors leur binaire précompilé, rien à compiler à la main).
3. **Fins de ligne** — `core.autocrlf=true` collerait du CRLF dans `bin/*` et `.kamal/hooks/*`,
   qui partent tels quels dans l'image Docker et n'y démarreraient plus (`#!/usr/bin/env ruby\r`).
   Le dépôt est donc en `core.autocrlf=false` + `core.fileMode=false` (le bit exécutable des
   `bin/*` ne survit pas à un checkout Windows, sans ça `git status` est bruyant en permanence).
4. **MSYS2** — le paquet winget `RubyInstallerTeam.RubyWithDevKit.3.3` pose MSYS2 mais le
   compilateur est dans `ucrt64\bin`, pas `mingw64\bin` ; `ridk install 3` complète la chaîne
   (nécessaire pour bootsnap et websocket-driver, qui n'ont pas de gem précompilée Windows).

Les `VIPS-WARNING … vips-heif.dll` au démarrage sont **sans conséquence** : libvips cherche des
modules de formats exotiques (HEIF, JXL, PDF) que le projet n'utilise pas.

Pour voir le jeu après `db:prepare` : crée un compte sur `/register`, puis en console
`Membership.create!(user: User.last, game: Game.first, team: Game.first.teams.first, balls: 20)`
et recharge le Hub.

**Plus simple — se connecter en démo** : le seed donne à tous les joueurs le mot de passe
`odyssea2027`. Connecte-toi avec **`yann@btb.test` / `odyssea2027`** (exotiques) pour tomber
directement dans une partie remplie. Le seed **rejoue de vrais événements par le pipeline complet**
(scoring → résolution piège/jambe → crédit des 🍑 → notifs, comme `StravaActivityImportJob`) :
- les **🍑 sont créditées par les courses** (`credit_balls!`), pas fixées à la main — chaque
  équipe a un vrai magot en banque et un solde par joueur cohérent avec son historique ;
- **les deux issues d'un piège** sont montrées : la course de Yann est **piégée mais déjouée**
  par sa jambe de bois (🍑 sauvées, notif importante), celle de Nico est **piégée** (0 🍑) ;
- **effets actifs** sur le Hud : vents (dos/face), **saladier** 🥣 retourné sur King-Coco,
  **jauge de meute**, **second souffle** de Framboitrix (soins à 1 🍑, donc elle est déjà à
  `wear` 3 — bien amochée), et le chip **🍦 Chantilly** sur les rouges ;
- **PV masqués « ??? »** + **chantilly dans les yeux de Framboitrix** en se connectant en
  **`max@btb.test`** (les rouges sont barbouillés ; Yann/exo, lui, garde une vue complète) ;
- **deux courses refusées** par le contrôle anti-triche (tapis sans preuve de Léa, balade à
  10:59/km de Nico) : notif importante avec le motif, sortie visible mais à 0 🍑 ;
- le fil de notifications (importantes vs secondaires) et la **pastille de non-lus** du Chat.

Reseeder (`bin/rails db:seed`) régénère tout ça. La **famine** (🍽️) et la **fin de partie** (🏁)
ne sont pas forcées dans le seed : ce sont des jobs temporels et les déclencher abîmerait l'état
de démo (équipe affamée / partie terminée).
⚠️ Le seed doit détacher `games.winner_team_id` avant de supprimer les équipes, et vider
`ConversationRead` en tête du nettoyage (FK).

### Secrets (optionnels — l'app tourne sans)
`GOOGLE_CLIENT_ID/SECRET`, `STRAVA_CLIENT_ID/SECRET`, `STRAVA_VERIFY_TOKEN`,
`VAPID_PUBLIC_KEY/PRIVATE_KEY` (ou dans les credentials Rails). Sans eux, Google/Strava/push
sont simplement inactifs.

## Conventions

- Logique métier dans des **services** (`app/services`) et des **jobs**, contrôleurs fins.
- Écrans = pages Inertia rendues via `render inertia: "Nom", props: {...}` (pas d'API JSON séparée).
- Formulaires Inertia : inclure `authenticity_token` dans les données (CSRF).
- Commits clairs ; garder le seed à jour quand le schéma change.
