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

**Scoring d'une course** (`TrainingScorer`) : plafond d'abord, multiplicateurs ensuite —
15 km = 10 🍑, ×1,5 avec un vent de dos = 15 🍑. Un jour spécial ×2 double aussi le plafond
effectif. Les 🍑 sont **créditées à l'import** (`Training#credit_balls!`, idempotent) ; les
courses sont auto-vérifiées (`status: "verified"`), `Training.scoring` = verified + protected.
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
- **Partie** : `Event`, `Game`, `Team`, `Monster` (PV), `TeamEffect` (vent/bouclier), `SpecialDay`
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
5. **Combat** (service `PerformAction` : attaque/soin/objet, PV, bouclier, vent), **Chat**
   (partie + équipe), **Notifications + Web Push** (VAPID, service worker)
6. **Strava temps réel** : Webhook Events API (`/strava/webhook` verify + event), OAuth connect,
   refresh de token, job d'import ; reconciliation quotidienne en filet de sécurité
7. **Classement** (`/ligue`) : deux classements, mensuel et général, récompense au 1er du mois
8. **Avatar** (`/avatar`) : personnalisation + équipement des cosmétiques possédés
9. **Mécaniques de saison** (voir section dédiée) : jauge de meute, monstre affamé, second
   souffle, vent de face, fumigène, résolution des pièges au scoring, fin de partie

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
- **🌫️ Fumigène** : `TeamEffect kind: "smoke"` 24h sur l'équipe **aveuglée** (choisie par le
  poseur, sélecteur `TeamPicker`). `MonsterPresenter` masque alors hp/max_hp/percent
  (`masked: true`) pour ce viewer sur Hub et Combat — l'état (dessin) reste visible.
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
  fruit en **SVG** (silhouette + visage commun + ancres cosmétiques fixes, pas d'assets). Toute
  clé ajoutée dans le catalogue Ruby doit avoir son pendant visuel dans `components/fruits.js`.
- Choix **partageable** : plusieurs coéquipiers peuvent prendre le même fruit ; l'écran indique
  « déjà : X » sous chaque fruit. Le fruit doit appartenir à la famille de l'équipe (validé).
- Les **cosmétiques** possédés s'équipent **un par slot** (hat / eyes / outfit / arms / legs /
  aura), et `cosmetics.emoji` est ce qui les rend affichables. Les ancres SVG sont fixes → un
  cosmétique tombe au même endroit sur tous les fruits. **Catalogue : ~33 pièces** dans le seed
  (tous les slots garnis, grille 100/250/500/1000) dont 5 **exclusives** `price_diamonds: nil`
  (sources `event`/`rank`/`drop` : Noël, Halloween, médaille, loup…) — jamais en vente, mais
  **tirables** par les cadeaux de streak et de ligue (comportement assumé, comme la Couronne).
  Ajouter une pièce = une ligne dans le seed (slot existant + emoji), aucun code.

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
Bellatrix Lestrange) pour Odyssea. Un slug inconnu retombe sur un emoji 👾. En **Combat**, l'attaque secoue + flashe en rouge le monstre
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
  **Fumigène 4** · **Piège à loup 5** · **Bouclier 6** (6h). Le vent de face notifie ses
  victimes nominativement (agressivité assumée) ; le fumigène choisit son équipe cible.
- **Cosmétiques** en 💎 diamants (`User.diamonds`, global) → déposés dans l'armoire
  (`UserCosmetic`). On les **équipe / remet dans l'armoire** depuis l'écran avatar (`/avatar`).
  Seuls les cosmétiques `price_diamonds` non nul sont en vente (les récompenses ne le sont pas).

Trois onglets : Objets · Cosmétiques · Sac (inventaire des objets + lien vers l'armoire). Les
achats sont refusés proprement si monnaie insuffisante, cosmétique déjà possédé, ou pas d'équipe.

### Notifications — deux niveaux (`notifications.importance`)
- **important** : poussé en Web Push **et** listé. Concerne le joueur directement — message dans
  la **conversation d'équipe**, récompense (coffre, ligue, streak), « ma course a été piégée /
  mon piège a réussi / mon piège a été déjoué », vent de face ou fumigène **reçu**, palier de
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
le bouclier du monstre (`monster.protected_until`), chacun avec son échéance. Affichés par
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
`Faq`, `auth/Login`, `auth/Register`.
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

## Roadmap (à faire, ordre suggéré)

1. **Admin de partie** — créer Event/Game/Teams, valider les courses `pending`.
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
```

⚠️ **Vite 8 exige Node ≥ 20.12** (`node:util#styleText`). Node 16 fait planter `bin/dev` avec
`SyntaxError: … does not provide an export named 'styleText'` — `nvm use 22` avant de lancer.

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
- **effets actifs** sur le Hud : vents (dos/face), bouclier, **jauge de meute**, **second souffle**
  de Framboitrix (soins à 1 🍑), et le chip **🌫️ Enfumée** sur les rouges ;
- **PV masqués « ??? »** visibles en se connectant en **`max@btb.test`** (les rouges sont enfumés ;
  Yann/exo, lui, garde une vue complète) ;
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
