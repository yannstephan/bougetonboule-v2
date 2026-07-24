# Bouge Ton Boule v2 — Contexte projet

> Ce fichier est lu automatiquement par Claude Code. Il résume le jeu, la stack,
> le modèle de données, ce qui est déjà construit, le design et la roadmap.

## Le concept

Jeu de **course à pied entre amis**. Chaque km couru (importé depuis **Strava**) rapporte
**1 pêche 🍑** (max 10 / sortie). On dépense ses pêches pour **attaquer** le monstre de
l'équipe adverse ou **soigner** le sien. Deux clans s'affrontent : **🍋 Zeste Solaire
(Citronator)** vs **🍓 Chair Écarlate (Fraizilla)**. Quand les PV d'un monstre tombent à 0,
son équipe perd. C'est la v2 (front moderne) d'une app Rails existante jugée trop brouillonne.

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
ses 🍑/streak/courses sont **par partie**, son avatar/cosmétiques/💎 sont **globaux**.

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
7. **Ligue** : classement hebdo de la partie en 5 divisions, promotion/relégation le lundi

### La ligue (`/ligue`)
Une seule ligue par partie (les deux clans mélangés), 5 divisions : Bronze 🥉 · Argent 🥈 ·
Or 🥇 · Platine 💠 · Diamant 👑 (`Membership::DIVISIONS`, colonne `memberships.division`).

- **Score de la semaine** = somme des 🍑 des `Training` vérifiés de la semaine (lundi → dimanche).
  Il n'est **pas stocké** : `LeagueStandings` le recalcule, donc le classement repart de zéro
  tout seul chaque lundi — rien à remettre à zéro en base.
- **Promotion / relégation** : les 3 premiers montent, les 3 derniers descendent, plafonné à un
  tiers de l'effectif de la division pour que les deux zones ne se chevauchent jamais. Une
  semaine à 0 🍑 fait descendre quel que soit le rang. On ne descend pas sous Bronze.
- Les zones sont calculées **uniquement** dans `LeagueStandings#zone_for` : l'écran et le job
  de clôture doivent toujours être d'accord sur qui monte et qui descend.
- `LeagueWeeklyResetJob` (lundi 4h10, `config/recurring.yml`) juge la semaine **écoulée**,
  déplace les divisions, écrit `last_league_rank` / `last_league_result` et notifie (catégorie
  `league`).

### Écrans React existants (app/frontend/pages)
`Hub`, `Combat`, `Chat`, `Ligue`, `Notifications`, `auth/Login`, `auth/Register`.
Navigation par onglets : **Hub · Chat · ⚔️ Combat · Ligue · Boutique** (`components/BottomNav.jsx`).
Seule la Boutique est encore **grisée** (à construire).

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

1. **Boutique** — cosmétiques en 💎 (par rareté) + power-ups en 🍑 ; achat, inventaire ; écran + onglet.
2. **Coffres** — drop aléatoire à l'import d'une course (garde-fou : max 1/jour, pity),
   ouverture animée (💎 + cosmétique), notif "coffre trouvé".
3. **Streak hebdo** — job hebdomadaire (Solid Queue `recurring.yml`) : +💎 par semaine courue, paliers.
4. **Avatar & cosmétiques** — personnalisation (slots), équiper les cosmétiques gagnés.
5. **PWA installable** — manifest + icône 🍑, activer les routes PWA (déjà stubbées).
6. **Admin de partie** — créer Event/Game/Teams, valider les courses `pending`.

## Commandes utiles

```bash
bin/dev                 # Rails + Vite → http://localhost:3000
bin/rails db:prepare    # crée + migre + seed
bin/rails console
bin/rails webpush:keys              # génère les clés VAPID
CALLBACK_URL=https://.../strava/webhook bin/rails strava:subscribe  # abonnement webhook (prod)

bin/rails league:standings          # classement de la semaine en cours, en console
WEEK_START=2026-07-20 bin/rails league:close_week   # clôture une semaine à la main (test)
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
