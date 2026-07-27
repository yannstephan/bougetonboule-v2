# Bouge Ton Boule v2 — Contexte projet

> Ce fichier est lu automatiquement par Claude Code. Il résume le jeu, la stack,
> le modèle de données, ce qui est déjà construit, le design et la roadmap.

## Le concept

Jeu de **course à pied entre amis**. Chaque km couru (importé depuis **Strava**) rapporte
**1 pêche 🍑** (max 10 / sortie). On dépense ses pêches pour **attaquer** le monstre de
l'équipe adverse ou **soigner** le sien. Quand les PV d'un monstre tombent à 0, son équipe perd.
C'est la v2 (front moderne) d'une app Rails existante jugée trop brouillonne.

L'événement **Odyssea 2027** (mars 2027) oppose deux clans : **🌴 Fruits exotiques** (monstre
**King-Coco**) vs **🍒 Fruits rouges** (monstre **Dracassis**). Chaque joueur choisit un
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
| 🍑 **Pêches** | **courir uniquement** (1/km, max 10) | combat + power-ups | **par partie** (`Membership.balls`) |
| 💎 **Diamants** | streaks, jours spéciaux, coffres, fin de partie | **cosmétiques uniquement** | **globale** (`User.diamonds`) |

On n'achète jamais de pêches ni d'avantage de combat. Les 💎 ne touchent qu'au cosmétique.

## Modèle de données (21 tables — voir db/schema.rb)

Séparation clé : **Event** (la course réelle, ex. Odyssea 2027) → **Game/partie** →
**Membership** (un user dans une partie, dans une équipe). Un user joue plusieurs parties ;
ses 🍑/streak/courses **et son fruit-avatar** (`memberships.fruit`) sont **par partie**, ses
cosmétiques/💎 sont **globaux**.

- **Compte** : `User`, `Avatar`, `Cosmetic`, `UserCosmetic`, `PushSubscription`, `Notification`
- **Partie** : `Event`, `Game`, `Team`, `Monster` (PV), `TeamEffect` (vent/bouclier), `SpecialDay`
- **Participation** : `Membership`, `Training` (course Strava scorée)
- **Combat/éco** : `Item`, `MembershipItem`, `Action` (attaque/soin/objet, cible polymorphe),
  `Chest` (coffre), `Reward` (registre des gains)
- **Social** : `Conversation` (kind `general` = toute la partie, ou `team` = privé équipe), `Message`

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
- Les **cosmétiques** possédés s'équipent **un par slot** (hat / eyes / outfit / aura), et
  `cosmetics.emoji` est ce qui les rend affichables. Les ancres SVG sont fixes → un cosmétique
  tombe au même endroit sur tous les fruits.

`AvatarPresenter.new(user, membership:)` est le **seul** endroit qui sérialise un avatar (fruit +
cosmétiques), affiché dans le Hub, le chat, le classement et l'écran avatar. Côté React, le
composant unique est `components/PlayerAvatar.jsx` (délègue à `FruitAvatar`, pastille + initiale
en secours si pas de fruit).

### Les monstres
Dessinés en SVG dans `components/Monster.jsx`, choisis par `Monster#slug` (`"King-Coco"` →
`king-coco`). King-Coco (roi noix de coco) et Dracassis (dragon cassis) pour Odyssea. Un slug
inconnu retombe sur un emoji 👾.

### Profils & sorties (`/joueurs/:id`, `/courses/:id`)
Chaque **participation** (Membership) a une page profil consultable par **tout joueur de la même
partie** (les deux clans — `ApplicationController#shares_game?`). Elle liste ses sorties (date,
heure, km, 🍑, statut) et lie vers le détail de chacune.

Le **détail d'une sortie** (`/courses/:id`) montre ce qu'on récupère de Strava : titre,
description, durée, allure, dénivelé, **tracé du parcours** et photo. Les champs sont stockés sur
`trainings` (`title`, `description`, `moving_time`, `elapsed_time`, `elevation_gain`,
`route_points`, `photo_url`) et remplis à l'import (`StravaActivityImportJob`).

- Le **tracé** est dessiné en **SVG** (`components/RouteMap.jsx`) à partir de `route_points`
  (`[[lat, lng], …]`) — pas de fond de carte, pas de service tiers (objectif ~5-6 €/mois). La
  polyline Strava est décodée à l'import par le module `Polyline`.
- `TrainingPresenter` sérialise une sortie (résumé pour la liste, détail pour la page) — seul
  endroit qui formate dates, durées et allure.
- Les **noms sont cliquables** vers le profil dans le chat et la ligue (et l'avatar au chat).

### La boutique (`/boutique`)
Deux monnaies **étanches** (règle d'or, jamais de pay-to-win), servies par le service `Purchase` :
- **Objets** (power-ups) en 🍑 pêches (`Membership.balls`, par partie) → déposés dans l'inventaire
  de la participation (`MembershipItem`, `used: false`). **À usage unique** : « Utiliser » réutilise
  `PerformAction` (`use_item`) et consomme l'objet.
- **Cosmétiques** en 💎 diamants (`User.diamonds`, global) → déposés dans l'armoire
  (`UserCosmetic`). On les **équipe / remet dans l'armoire** depuis l'écran avatar (`/avatar`).
  Seuls les cosmétiques `price_diamonds` non nul sont en vente (les récompenses ne le sont pas).

Trois onglets : Objets · Cosmétiques · Sac (inventaire des objets + lien vers l'armoire). Les
achats sont refusés proprement si monnaie insuffisante, cosmétique déjà possédé, ou pas d'équipe.

### Notifications — deux niveaux (`notifications.importance`)
- **important** : poussé en Web Push **et** listé. Concerne le joueur directement — message dans
  la **conversation d'équipe**, récompense (coffre, ligue, streak), et (à venir) « ma course a été
  piégée / mon piège a réussi / mon piège a été déjoué ».
- **secondary** (défaut) : **listé seulement**, jamais poussé. L'activité des autres — « X a
  couru N km », « X a activé un vent de dos jusqu'à… », « X a posé un piège à loup », chat
  général, combat.

Le push n'est déclenché que pour les importantes (`Notification#push_if_important`).
`Notification.broadcast(users, importance:, …)` crée la même notif pour plusieurs destinataires.
L'écran Notifications sépare **Pour toi** (importantes) et **Activité de la partie** (secondaires,
style atténué).

### Profil : pas de solde de 🍑
La réserve de pêches d'un joueur ne se voit **que sur sa propre page d'accueil** (le HUD), jamais
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
- ⚠️ **Les effets sur les courses ne sont pas encore résolus** (piège annulant les 🍑, jambe de
  bois les protégeant) : les objets se posent et s'affichent, mais le scoring des `Training`
  n'est pas encore touché. À faire avec les coffres/streak.

### Écrans React existants (app/frontend/pages)
`Hub`, `Combat`, `Chat`, `Ligue`, `Avatar`, `Boutique`, `Profile`, `Training`, `Notifications`,
`auth/Login`, `auth/Register`.
Navigation par onglets : **Hub · Chat · ⚔️ Combat · Ligue · Boutique** (`components/BottomNav.jsx`),
tous actifs.

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

1. **Coffres** — drop aléatoire à l'import d'une course (garde-fou : max 1/jour, pity),
   ouverture animée (💎 + cosmétique), notif "coffre trouvé".
2. **Streak hebdo** — job hebdomadaire (Solid Queue `recurring.yml`) : +💎 par semaine courue, paliers.
3. **PWA installable** — manifest + icône 🍑, activer les routes PWA (déjà stubbées).
4. **Admin de partie** — créer Event/Game/Teams, valider les courses `pending`.
5. **Rejoindre une partie depuis l'app** — aujourd'hui un `Membership` se crée encore à la main
   en console, il n'y a pas d'écran pour rejoindre une équipe.

## Commandes utiles

```bash
bin/dev                 # Rails + Vite → http://localhost:3000
bin/rails db:prepare    # crée + migre + seed
bin/rails console
bin/rails webpush:keys              # génère les clés VAPID
CALLBACK_URL=https://.../strava/webhook bin/rails strava:subscribe  # abonnement webhook (prod)

bin/rails league:standings          # classements du mois et général, en console
MONTH=2026-06 bin/rails league:award_month         # décerne la récompense d'un mois (test)
```

⚠️ **Vite 8 exige Node ≥ 20.12** (`node:util#styleText`). Node 16 fait planter `bin/dev` avec
`SyntaxError: … does not provide an export named 'styleText'` — `nvm use 22` avant de lancer.

Pour voir le jeu après `db:prepare` : crée un compte sur `/register`, puis en console
`Membership.create!(user: User.last, game: Game.first, team: Game.first.teams.first, balls: 20)`
et recharge le Hub.

### Secrets (optionnels — l'app tourne sans)
`GOOGLE_CLIENT_ID/SECRET`, `STRAVA_CLIENT_ID/SECRET`, `STRAVA_VERIFY_TOKEN`,
`VAPID_PUBLIC_KEY/PRIVATE_KEY` (ou dans les credentials Rails). Sans eux, Google/Strava/push
sont simplement inactifs.

## Conventions

- Logique métier dans des **services** (`app/services`) et des **jobs**, contrôleurs fins.
- Écrans = pages Inertia rendues via `render inertia: "Nom", props: {...}` (pas d'API JSON séparée).
- Formulaires Inertia : inclure `authenticity_token` dans les données (CSRF).
- Commits clairs ; garder le seed à jour quand le schéma change.
