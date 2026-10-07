import { Head, router, usePage } from '@inertiajs/react'
import { useState } from 'react'
import { CosmeticIcon } from '../components/cosmeticArt'
import Hud from '../components/Hud'
import BottomNav from '../components/BottomNav'
import { csrf } from '../lib/csrf'

const slotLabel = { hat: 'Chapeau', eyes: 'Lunettes', neck: 'Cou', hands: 'Bras',
  shoes: 'Chaussures', sidekick: 'Accessoire', aura: 'Aura' }

// Back-office de l'organisateur : les deux réglages qui se pilotent par des dates et qu'on
// veut pouvoir changer sans redéployer — journées ×2 et fenêtres de la boutique de saison.
export default function Admin({ game, today, special_days, cosmetics, teams, players, unassigned_users }) {
  const { flash } = usePage().props
  const [tab, setTab] = useState('players')

  return (
    <div className="shell">
      <Head title="Organisation" />
      <Hud />

      <main className="body">
        {flash?.notice && <div className="flash ok">{flash.notice}</div>}
        {flash?.alert && <div className="flash err">{flash.alert}</div>}

        <p className="av-hint">Partie « {game.name} ». Ces réglages prennent effet tout de suite.</p>

        <div className="adm-tabs">
          <button className={`adm-tab ${tab === 'players' ? 'on' : ''}`} onClick={() => setTab('players')}>
            👥 Joueurs
          </button>
          <button className={`adm-tab ${tab === 'days' ? 'on' : ''}`} onClick={() => setTab('days')}>
            🎉 Journées ×2
          </button>
          <button className={`adm-tab ${tab === 'shop' ? 'on' : ''}`} onClick={() => setTab('shop')}>
            ✨ Boutique de saison
          </button>
        </div>

        {tab === 'players' && <Players teams={teams} players={players} unassigned={unassigned_users} />}
        {tab === 'days' && <SpecialDays days={special_days} today={today} />}
        {tab === 'shop' && <SeasonalShop cosmetics={cosmetics} />}
      </main>

      <BottomNav />
    </div>
  )
}

// Affectation des joueurs : chaque équipe liste ses membres (changement d'équipe en un
// select), et les comptes pas encore dans la partie attendent en dessous — c'est le seul
// chemin pour rejoindre une partie, il n'y a pas d'auto-inscription.
function Players({ teams, players, unassigned }) {
  const byTeam = (teamId) => players.filter((p) => p.team_id === teamId)

  const assign = (userId, teamId) => {
    router.post('/admin/joueurs', { user_id: userId, team_id: teamId, authenticity_token: csrf() },
      { preserveScroll: true })
  }
  const move = (membershipId, teamId) => {
    if (!confirm("Déplacer ce joueur ? Son fruit-avatar sera remis à zéro (la nouvelle équipe n'a pas forcément les mêmes fruits).")) return
    router.patch(`/admin/joueurs/${membershipId}`, { team_id: teamId, authenticity_token: csrf() },
      { preserveScroll: true })
  }

  return (
    <section className="av-sec">
      {teams.map((t) => (
        <div key={t.id} className="adm-team">
          <h3 className="adm-team-h">{t.name}</h3>
          {byTeam(t.id).length === 0 ? (
            <p className="av-empty">Personne pour l'instant.</p>
          ) : (
            <div className="adm-list">
              {byTeam(t.id).map((p) => (
                <div key={p.id} className="adm-item">
                  <div className="adm-info">
                    <div className="adm-name">{p.name}{p.admin && ' · admin'}</div>
                    <div className="adm-sub">{p.email}</div>
                  </div>
                  <select className="field" value={p.team_id}
                          onChange={(e) => move(p.id, Number(e.target.value))}>
                    {teams.map((tt) => <option key={tt.id} value={tt.id}>{tt.name}</option>)}
                  </select>
                </div>
              ))}
            </div>
          )}
        </div>
      ))}

      <h2>Pas encore affecté·e</h2>
      {unassigned.length === 0 ? (
        <p className="av-empty">Tout le monde a une équipe.</p>
      ) : (
        <div className="adm-list">
          {unassigned.map((u) => <UnassignedRow key={u.id} user={u} teams={teams} onAssign={assign} />)}
        </div>
      )}
    </section>
  )
}

function UnassignedRow({ user, teams, onAssign }) {
  const [teamId, setTeamId] = useState(teams[0]?.id)

  return (
    <div className="adm-item">
      <div className="adm-info">
        <div className="adm-name">{user.name}</div>
        <div className="adm-sub">{user.email}</div>
      </div>
      <select className="field" value={teamId} onChange={(e) => setTeamId(Number(e.target.value))}>
        {teams.map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}
      </select>
      <button className="adm-save" onClick={() => onAssign(user.id, teamId)}>Affecter</button>
    </div>
  )
}

function SpecialDays({ days, today }) {
  const [name, setName] = useState('')
  const [date, setDate] = useState(today)
  const [multiplier, setMultiplier] = useState(2)

  const add = (e) => {
    e.preventDefault()
    router.post('/admin/journees', { name, date, multiplier, authenticity_token: csrf() },
      { preserveScroll: true, onSuccess: () => setName('') })
  }

  const remove = (d) => {
    if (!confirm(`Supprimer « ${d.name} » ?`)) return
    router.delete(`/admin/journees/${d.id}`, { data: { authenticity_token: csrf() }, preserveScroll: true })
  }

  return (
    <section className="av-sec">
      <h2>Journées spéciales</h2>
      <p className="av-hint">
        Une journée ×2 double les boules gagnées <em>et</em> le plafond du jour. Compte 5 à 6 par
        saison : au-delà, l'effet de surprise s'émousse.
      </p>

      <form className="adm-form" onSubmit={add}>
        <input className="field" placeholder="Nom (ex. Halloween)" value={name} required
               onChange={(e) => setName(e.target.value)} />
        <div className="adm-row">
          <input className="field" type="date" value={date} required onChange={(e) => setDate(e.target.value)} />
          <select className="field" value={multiplier} onChange={(e) => setMultiplier(Number(e.target.value))}>
            <option value={2}>×2</option>
            <option value={3}>×3</option>
          </select>
        </div>
        <button className="btn primary" type="submit">Ajouter la journée</button>
      </form>

      {days.length === 0 ? (
        <p className="av-empty">Aucune journée spéciale pour l'instant.</p>
      ) : (
        <div className="adm-list">
          {days.map((d) => (
            <div key={d.id} className={`adm-item ${d.past ? 'past' : ''}`}>
              <span className="adm-mult">×{d.multiplier}</span>
              <div className="adm-info">
                <div className="adm-name">{d.name}</div>
                <div className="adm-sub">{frDate(d.date)}{d.past && ' · passée'}</div>
              </div>
              <button className="adm-del" onClick={() => remove(d)} aria-label="Supprimer">✕</button>
            </div>
          ))}
        </div>
      )}
    </section>
  )
}

function SeasonalShop({ cosmetics }) {
  const [scope, setScope] = useState('all')
  const [query, setQuery] = useState('')

  const dated = cosmetics.filter((c) => c.available_from || c.available_until)
  const q = query.trim().toLowerCase()
  const list = (scope === 'dated' ? dated : cosmetics)
    .filter((c) => !q || c.name.toLowerCase().includes(q))

  return (
    <section className="av-sec">
      <h2>Fenêtres de disponibilité</h2>
      <p className="av-hint">
        Une pièce sans date est en vente toute l'année. Poser une date la fait entrer dans la
        boutique de saison : hors de sa fenêtre elle disparaît de la boutique <em>et</em> des
        tirages (coffre, série, ligue) — mais reste acquise à ceux qui l'ont déjà.
      </p>

      {/* Filtre d'AFFICHAGE seulement : il ne touche à aucune pièce. */}
      <div className="adm-filter">
        <div className="adm-scope">
          <button className={scope === 'all' ? 'on' : ''} onClick={() => setScope('all')}>
            Tout le catalogue · {cosmetics.length}
          </button>
          <button className={scope === 'dated' ? 'on' : ''} onClick={() => setScope('dated')}>
            Déjà datées · {dated.length}
          </button>
        </div>
        <input className="field" type="search" placeholder="Chercher une pièce…" value={query}
               onChange={(e) => setQuery(e.target.value)} />
      </div>

      {list.length === 0 ? (
        <p className="av-empty">Aucune pièce ne correspond.</p>
      ) : (
        <div className="adm-list">
          {list.map((c) => <CosmeticRow key={c.id} c={c} />)}
        </div>
      )}
    </section>
  )
}

function CosmeticRow({ c }) {
  const [from, setFrom] = useState(c.available_from || '')
  const [until, setUntil] = useState(c.available_until || '')
  const dirty = from !== (c.available_from || '') || until !== (c.available_until || '')

  const save = () => {
    router.patch(`/admin/cosmetiques/${c.id}`,
      { available_from: from, available_until: until, authenticity_token: csrf() },
      { preserveScroll: true })
  }

  return (
    <div className="adm-cos">
      <div className="adm-cos-head">
        <CosmeticIcon art={c.art} emoji={c.emoji} className="adm-cos-icon" />
        <div className="adm-info">
          <div className="adm-name">{c.name}</div>
          <div className="adm-sub">
            {slotLabel[c.slot] || c.slot} · {c.price ? `${c.price} 💎` : 'hors vente'}
            {!c.live && ' · hors fenêtre'}
          </div>
        </div>
        {c.live && (c.available_from || c.available_until) && <span className="adm-live">en cours</span>}
      </div>
      <div className="adm-row">
        <label className="adm-date"><span>du</span>
          <input className="field" type="date" value={from} onChange={(e) => setFrom(e.target.value)} />
        </label>
        <label className="adm-date"><span>au</span>
          <input className="field" type="date" value={until} onChange={(e) => setUntil(e.target.value)} />
        </label>
        <button className="adm-save" disabled={!dirty} onClick={save}>OK</button>
      </div>
    </div>
  )
}

const frDate = (iso) => {
  const [y, m, d] = iso.split('-')
  return `${d}/${m}/${y}`
}
