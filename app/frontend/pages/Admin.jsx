import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'
import { CosmeticIcon } from '../components/cosmeticArt'

const csrf = () =>
  (typeof document !== 'undefined' && document.querySelector('meta[name=csrf-token]')?.content) || ''

const slotLabel = { hat: 'Chapeau', eyes: 'Lunettes', neck: 'Cou', hands: 'Bras',
  shoes: 'Chaussures', sidekick: 'Accessoire', aura: 'Aura' }

// Back-office de l'organisateur : les deux réglages qui se pilotent par des dates et qu'on
// veut pouvoir changer sans redéployer — journées ×2 et fenêtres de la boutique de saison.
export default function Admin({ game, today, special_days, cosmetics }) {
  const { flash } = usePage().props
  const [tab, setTab] = useState('days')

  return (
    <div className="shell">
      <Head title="Organisation" />
      <div className="subhead">
        <Link href="/" className="back">←</Link>
        <div className="ti">🛠️ Organisation</div>
      </div>

      <main className="body">
        {flash?.notice && <div className="flash ok">{flash.notice}</div>}
        {flash?.alert && <div className="flash err">{flash.alert}</div>}

        <p className="av-hint">Partie « {game.name} ». Ces réglages prennent effet tout de suite.</p>

        <div className="adm-tabs">
          <button className={`adm-tab ${tab === 'days' ? 'on' : ''}`} onClick={() => setTab('days')}>
            🎉 Journées ×2
          </button>
          <button className={`adm-tab ${tab === 'shop' ? 'on' : ''}`} onClick={() => setTab('shop')}>
            ✨ Boutique de saison
          </button>
        </div>

        {tab === 'days'
          ? <SpecialDays days={special_days} today={today} />
          : <SeasonalShop cosmetics={cosmetics} />}
      </main>
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
  const [onlyDated, setOnlyDated] = useState(false)
  const list = onlyDated ? cosmetics.filter((c) => c.available_from || c.available_until) : cosmetics

  return (
    <section className="av-sec">
      <h2>Fenêtres de disponibilité</h2>
      <p className="av-hint">
        Laisse les deux dates vides pour une pièce permanente. Hors fenêtre, elle disparaît de la
        boutique <em>et</em> des tirages (coffre, série, ligue) — mais reste acquise à ceux qui
        l'ont déjà.
      </p>
      <label className="adm-check">
        <input type="checkbox" checked={onlyDated} onChange={(e) => setOnlyDated(e.target.checked)} />
        N'afficher que les pièces datées
      </label>

      <div className="adm-list">
        {list.map((c) => <CosmeticRow key={c.id} c={c} />)}
      </div>
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
