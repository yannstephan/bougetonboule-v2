import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'
import BottomNav from '../components/BottomNav'
import PlayerAvatar from '../components/PlayerAvatar'
import BuyConfirm from '../components/BuyConfirm'
import { CosmeticIcon } from '../components/cosmeticArt'
import Hud from '../components/Hud'

const csrf = () =>
  (typeof document !== 'undefined' && document.querySelector('meta[name=csrf-token]')?.content) || ''

const itemEmoji = (t) =>
  ({ shield: '🥣', trap: '🐺', back_wind: '🌬️', face_wind: '🌪️', smoke: '🍦', wooden_leg: '🦿' }[t] || '🎒')
const rarityLabel = { common: 'Commun', rare: 'Rare', epic: 'Épique', legendary: 'Légendaire' }

export default function Boutique({ has_team, initial_tab, balls, items, cosmetics, seasonal, avatar }) {
  const { auth, flash } = usePage().props
  const diamonds = auth.user?.diamonds ?? 0
  const [tab, setTab] = useState(initial_tab || 'items')
  // Achat en attente de confirmation. Rien n'est envoyé tant qu'il est là.
  const [buy, setBuy] = useState(null)

  const post = (url, data) => router.post(url, { ...data, authenticity_token: csrf() }, { preserveScroll: true })
  const confirmBuy = () => {
    post(buy.url, buy.payload)
    setBuy(null)
  }
  const askItem = (it) => setBuy({
    url: '/boutique/items', payload: { item_id: it.id },
    name: it.name, description: it.description, price: it.price, currency: '🍑',
    emoji: itemEmoji(it.effect_type), balance: balls
  })
  const askCosmetic = (c) => setBuy({
    url: '/boutique/cosmetics', payload: { cosmetic_id: c.id },
    name: c.name, price: c.price, currency: '💎', emoji: c.emoji, art: c.art, slot: c.slot,
    balance: diamonds
  })

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
        {tab === 'items' && <Items items={items} balls={balls} hasTeam={has_team} onBuy={askItem} />}
        {tab === 'cosmetics' && (
          <Cosmetics cosmetics={cosmetics} seasonal={seasonal} diamonds={diamonds}
                     onBuy={askCosmetic} avatar={avatar} />
        )}
      </main>

      <BuyConfirm buy={buy} avatar={avatar} onConfirm={confirmBuy} onClose={() => setBuy(null)} />

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
          <button className="shop-buy" disabled={balls < it.price} onClick={() => onBuy(it)}>
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

// Le rayon des cosmétiques, avec la CABINE D'ESSAYAGE en tête : on touche une pièce, elle
// se pose sur son propre fruit, et on décide en la voyant plutôt qu'en lisant son nom.
// Même geste que l'armoire du sac (aperçu collé en haut pendant qu'on fouille), pour que le
// joueur n'ait pas deux interactions à apprendre.
//
// L'essayage est PUREMENT LOCAL : rien n'est envoyé au serveur, ce qu'on porte vraiment ne
// bouge pas. Une pièce essayée remplace seulement son emplacement dans l'aperçu, donc on
// peut composer une tenue complète avant d'acheter quoi que ce soit.
function Cosmetics({ cosmetics, seasonal = [], diamonds, onBuy, avatar }) {
  const [tried, setTried] = useState({}) // { slot: cosmétique }

  const tryOn = (c) =>
    setTried((t) => (t[c.slot]?.id === c.id ? omit(t, c.slot) : { ...t, [c.slot]: c }))

  const worn = Object.values(tried)
  const preview = {
    ...avatar,
    cosmetics: {
      ...avatar?.cosmetics,
      ...Object.fromEntries(worn.map((c) => [c.slot, { emoji: c.emoji, art: c.art }]))
    }
  }

  return (
    <>
      {avatar?.fruit && (
        <div className="av-sticky">
          <div className="av-stage"><PlayerAvatar avatar={preview} size={132} /></div>
          <div className="shop-try">
            {worn.length === 0
              ? <span className="shop-try-hint">Touche une pièce pour l'essayer sur ton fruit.</span>
              : (
                <>
                  <span className="shop-try-list">Essai : {worn.map((c) => c.name).join(' · ')}</span>
                  <button type="button" className="shop-try-off" onClick={() => setTried({})}>Retirer</button>
                </>
              )}
          </div>
        </div>
      )}

      {seasonal.length > 0 && (
        <section className="shop-season">
          <div className="shop-season-head">
            <span className="t">✨ Boutique de saison</span>
            <span className="s">Ces pièces repartent bientôt — après, il faudra attendre l'an prochain.</span>
          </div>
          <CosmeticGrid list={seasonal} diamonds={diamonds} onBuy={onBuy} onTry={tryOn} tried={tried} season />
        </section>
      )}
      <CosmeticGrid list={cosmetics} diamonds={diamonds} onBuy={onBuy} onTry={tryOn} tried={tried} />
    </>
  )
}

const omit = (obj, key) => Object.fromEntries(Object.entries(obj).filter(([k]) => k !== key))

function CosmeticGrid({ list, diamonds, onBuy, onTry, tried, season = false }) {
  return (
    <div className="shop-grid">
      {list.map((c) => {
        const on = tried[c.slot]?.id === c.id
        return (
          <div key={c.id} className={`shop-cos ${c.rarity} ${season ? 'season' : ''} ${on ? 'trying' : ''}`}>
            {season && c.days_left != null && <span className="shop-cos-left">⏳ {daysLabel(c.days_left)}</span>}
            {/* Toute la vignette est le bouton d'essayage : c'est le geste le plus fréquent. */}
            <button type="button" className="shop-cos-try" onClick={() => onTry(c)}
                    aria-pressed={on} title={on ? 'Retirer de l\'essai' : `Essayer ${c.name}`}>
              <CosmeticIcon art={c.art} emoji={c.emoji} className="shop-cos-emoji" />
              <span className="shop-cos-name">{c.name}</span>
              <span className="shop-cos-rarity">{rarityLabel[c.rarity] || c.rarity}</span>
            </button>
            {c.owned ? (
              <Link href="/sac?tab=wardrobe" className="shop-owned">{c.equipped ? '✓ Équipé' : 'Dans l\'armoire'}</Link>
            ) : (
              <button className="shop-buy full" disabled={diamonds < c.price} onClick={() => onBuy(c)}>
                {c.price} 💎
              </button>
            )}
          </div>
        )
      })}
    </div>
  )
}
