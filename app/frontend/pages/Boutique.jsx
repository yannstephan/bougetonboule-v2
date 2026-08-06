import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'
import BottomNav from '../components/BottomNav'
import { CosmeticIcon } from '../components/cosmeticArt'
import Hud from '../components/Hud'

const csrf = () =>
  (typeof document !== 'undefined' && document.querySelector('meta[name=csrf-token]')?.content) || ''

const itemEmoji = (t) =>
  ({ shield: '🥣', trap: '🐺', back_wind: '🌬️', face_wind: '🌪️', smoke: '🍦', wooden_leg: '🦿' }[t] || '🎒')
const rarityLabel = { common: 'Commun', rare: 'Rare', epic: 'Épique', legendary: 'Légendaire' }

export default function Boutique({ has_team, initial_tab, balls, items, cosmetics, seasonal }) {
  const { auth, flash } = usePage().props
  const diamonds = auth.user?.diamonds ?? 0
  const [tab, setTab] = useState(initial_tab || 'items')

  const post = (url, data) => router.post(url, { ...data, authenticity_token: csrf() }, { preserveScroll: true })
  const buyItem = (id) => post('/boutique/items', { item_id: id })
  const buyCosmetic = (id) => post('/boutique/cosmetics', { cosmetic_id: id })

  return (
    <div className="shell">
      <Head title="Boutique" />
      <Hud />

      {flash?.notice && <div className="flash ok" style={{ margin: '10px 14px 0' }}>{flash.notice}</div>}
      {flash?.alert && <div className="flash err" style={{ margin: '10px 14px 0' }}>{flash.alert}</div>}

      <div className="chat-tabs">
        <button className={`chat-tab ${tab === 'items' ? 'on' : ''}`} onClick={() => setTab('items')}>🍑 Objets</button>
        <button className={`chat-tab ${tab === 'cosmetics' ? 'on' : ''}`} onClick={() => setTab('cosmetics')}>💎 Cosmétiques</button>
      </div>

      <main className="body">
        {tab === 'items' && <Items items={items} balls={balls} hasTeam={has_team} onBuy={buyItem} />}
        {tab === 'cosmetics' && <Cosmetics cosmetics={cosmetics} seasonal={seasonal} diamonds={diamonds} onBuy={buyCosmetic} />}
      </main>

      <BottomNav />
    </div>
  )
}

function Items({ items, balls, hasTeam, onBuy }) {
  if (!hasTeam) {
    return <p className="shop-empty">Rejoins une partie pour acheter des objets : ils s'achètent en 🍑 boules, gagnées en courant.</p>
  }
  return (
    <div className="shop-list">
      {items.map((it) => (
        <div key={it.id} className="shop-card">
          <span className="shop-emoji">{itemEmoji(it.effect_type)}</span>
          <div className="shop-info">
            <div className="shop-name">{it.name}{it.owned > 0 && <span className="shop-own">×{it.owned}</span>}</div>
            <div className="shop-desc">{it.description}</div>
          </div>
          <button className="shop-buy" disabled={balls < it.price} onClick={() => onBuy(it.id)}>
            {it.price} 🍑
          </button>
        </div>
      ))}
      <div className="shop-armoire">
        🎒 Ce que tu achètes atterrit dans ton sac — c'est là qu'on s'en sert.
        <Link href="/sac">Ouvrir mon sac →</Link>
      </div>
    </div>
  )
}

// Le compte à rebours d'une pièce de saison. 0 = dernier jour, on le dit franchement.
const daysLabel = (n) => (n === 0 ? 'Dernier jour !' : n === 1 ? 'Encore 1 jour' : `Encore ${n} jours`)

function Cosmetics({ cosmetics, seasonal = [], diamonds, onBuy }) {
  return (
    <>
      {seasonal.length > 0 && (
        <section className="shop-season">
          <div className="shop-season-head">
            <span className="t">✨ Boutique de saison</span>
            <span className="s">Ces pièces repartent bientôt — après, il faudra attendre l'an prochain.</span>
          </div>
          <CosmeticGrid list={seasonal} diamonds={diamonds} onBuy={onBuy} season />
        </section>
      )}
      <CosmeticGrid list={cosmetics} diamonds={diamonds} onBuy={onBuy} />
    </>
  )
}

function CosmeticGrid({ list, diamonds, onBuy, season = false }) {
  return (
    <div className="shop-grid">
      {list.map((c) => (
        <div key={c.id} className={`shop-cos ${c.rarity} ${season ? 'season' : ''}`}>
          {season && c.days_left != null && <span className="shop-cos-left">⏳ {daysLabel(c.days_left)}</span>}
          <CosmeticIcon art={c.art} emoji={c.emoji} className="shop-cos-emoji" />
          <div className="shop-cos-name">{c.name}</div>
          <div className="shop-cos-rarity">{rarityLabel[c.rarity] || c.rarity}</div>
          {c.owned ? (
            <Link href="/sac?tab=wardrobe" className="shop-owned">{c.equipped ? '✓ Équipé' : 'Dans l\'armoire'}</Link>
          ) : (
            <button className="shop-buy full" disabled={diamonds < c.price} onClick={() => onBuy(c.id)}>
              {c.price} 💎
            </button>
          )}
        </div>
      ))}
    </div>
  )
}
