import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'
import BottomNav from '../components/BottomNav'
import AuraBackground from '../components/AuraBackground'
import PlayerAvatar from '../components/PlayerAvatar'
import BuyConfirm from '../components/BuyConfirm'
import { CosmeticIcon } from '../components/cosmeticArt'
import Hud from '../components/Hud'
import { itemEmoji } from '../lib/gameIcons'
import { rarityLabel } from '../lib/rarity'

const csrf = () =>
  (typeof document !== 'undefined' && document.querySelector('meta[name=csrf-token]')?.content) || ''


export default function Boutique({ has_team, initial_tab, balls, items, cosmetics, seasonal, sets, avatar }) {
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
    rarity: c.rarity, balance: diamonds
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
                     sets={sets} onBuy={askCosmetic} avatar={avatar} />
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
function Cosmetics({ cosmetics, seasonal = [], sets = [], diamonds, onBuy, avatar }) {
  const [tried, setTried] = useState({}) // { slot: cosmétique }
  // La panoplie ouverte. Fermée, on ne voit d'elle qu'UNE carte : le rayon liste des tenues,
  // pas des pièces. Les pièces et leurs boutons n'apparaissent qu'une fois entré.
  const [openId, setOpenId] = useState(null)
  const open = sets.find((s) => s.id === openId)

  const tryOn = (c) =>
    setTried((t) => (t[c.slot]?.id === c.id ? omit(t, c.slot) : { ...t, [c.slot]: c }))
  // « Tout essayer » : la panoplie entière d'un coup dans la cabine. C'est la question qu'on
  // se pose devant une tenue — pas « et ce chapeau, il me va ? ».
  const tryAll = (set) =>
    setTried(Object.fromEntries(set.pieces.map((c) => [ c.slot, c ])))

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
          {/* Essayer une AURA change le fond de la cabine, pas l'avatar : c'est là que
              l'aura vit maintenant (voir AuraBackground). */}
          <div className="av-stage">
            <AuraBackground aura={preview?.cosmetics?.aura} local />
            <PlayerAvatar avatar={preview} size={132} />
          </div>
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

      {open ? (
        <SetShelf set={open} diamonds={diamonds} onBuy={onBuy} onTry={tryOn} tried={tried}
                  onBack={() => setOpenId(null)} onTryAll={() => tryAll(open)} />
      ) : (
        <>
          {sets.length > 0 && (
            <section className="av-sec">
              <h2>Panoplies · {sets.length}</h2>
              <div className="shop-sets">
                {sets.map((set) => (
                  <SetCard key={set.id} set={set} avatar={avatar} onOpen={() => setOpenId(set.id)} />
                ))}
              </div>
            </section>
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
          <section className="av-sec">
            <h2>À la pièce · {cosmetics.length}</h2>
            <CosmeticGrid list={cosmetics} diamonds={diamonds} onBuy={onBuy} onTry={tryOn} tried={tried} />
          </section>
        </>
      )}
    </>
  )
}

// La carte d'une panoplie : ce qu'on voit AVANT d'entrer. Elle montre la TENUE, portée sur
// son propre fruit — la question devant un rayon de panoplies est « est-ce que ça me va ? »,
// pas « combien coûte ce chapeau ». Le compteur et le reste à payer suffisent au reste.
// L'aperçu est monté exactement comme la cabine d'essai : mêmes pièces posées sur le même
// avatar, aucun aller-retour serveur. Et le FOND de la carte porte l'aura de la panoplie —
// c'est la seule façon de la montrer, puisqu'elle ne se pose pas sur l'avatar mais derrière
// l'écran : la carte donne donc à voir la tenue ET son décor, d'un coup.
function SetCard({ set, avatar, onOpen }) {
  const owned = set.pieces.filter((p) => p.owned).length
  const done = owned === set.pieces.length
  const left = set.pieces.filter((p) => !p.owned).reduce((n, p) => n + p.price, 0)
  const worn = {
    ...avatar,
    cosmetics: {
      ...avatar?.cosmetics,
      ...Object.fromEntries(set.pieces.map((c) => [ c.slot, { emoji: c.emoji, art: c.art } ]))
    }
  }

  return (
    <button type="button" className={`shop-set-card rar-tint rar-${set.rarity}`} onClick={onOpen}>
      <AuraBackground aura={set.reward} local />
      <span className="shop-set-look">
        <PlayerAvatar avatar={worn} size={96} />
      </span>
      <span className="shop-set-name">{set.name}</span>
      <span className="shop-set-meta">
        <span className={`shop-set-count ${done ? 'done' : ''}`}>
          {done ? '✓ complète' : `${owned}/${set.pieces.length}`}
        </span>
        {!done && <span className="shop-set-price">{left} 💎</span>}
      </span>
      {set.promo && <span className="shop-promo">−{set.promo.percent}%</span>}
      {set.days_left != null && <span className="shop-set-left">⏳ {daysLabel(set.days_left)}</span>}
    </button>
  )
}

// La panoplie OUVERTE : c'est seulement ici qu'apparaissent les pièces et leurs boutons.
// On achète toujours à la pièce — la panoplie range le rayon et porte la promo. Le compteur
// « 3/6 » dit où on en est : c'est ce qui donne envie de la finir.
function SetShelf({ set, diamonds, onBuy, onTry, tried, onBack, onTryAll }) {
  const owned = set.pieces.filter((p) => p.owned).length
  const done = owned === set.pieces.length
  return (
    <section className={`shop-set rar-tint rar-${set.rarity}`}>
      <div className="shop-set-nav">
        <button type="button" className="shop-back" onClick={onBack}>‹ Toutes les panoplies</button>
        <button type="button" className="shop-tryall" onClick={onTryAll}>Tout essayer</button>
      </div>
      <div className="shop-set-head">
        <span className="t">{set.name}</span>
        {set.days_left != null && (
          <span className="shop-cos-left" style={{ position: 'static', transform: 'none' }}>
            ⏳ {daysLabel(set.days_left)}
          </span>
        )}
        {set.promo && (
          <span className="shop-promo">−{set.promo.percent}% · {promoLabel(set.promo.days_left)}</span>
        )}
        <span className={`shop-set-count ${done ? 'done' : ''}`}>
          {done ? '✓ complète' : `${owned}/${set.pieces.length}`}
        </span>
      </div>
      {set.description && <p className="shop-set-desc">{set.description}</p>}
      <CosmeticGrid list={set.pieces} diamonds={diamonds} onBuy={onBuy} onTry={onTry} tried={tried} />
      {/* L'aura n'est pas une pièce du rayon : c'est la RÉCOMPENSE de la panoplie. Elle ne
          s'achète nulle part et ne tombe d'aucun coffre — c'est elle qui donne une raison de
          finir la collection, donc elle se montre AVANT d'être gagnée. */}
      {set.reward && (
        <div className={`shop-reward ${set.reward.owned ? 'got' : ''}`}>
          <CosmeticIcon art={set.reward.art} emoji={set.reward.emoji} className="shop-reward-icon" />
          <div className="shop-reward-text">
            <div className="shop-reward-name">✨ {set.reward.name}</div>
            <div className="shop-reward-sub">
              {set.reward.owned
                ? "Débloquée — ton fond d'écran t'attend dans l'armoire."
                : `Aura offerte quand la panoplie est complète · encore ${set.pieces.length - owned} pièce${set.pieces.length - owned > 1 ? 's' : ''}`}
            </div>
          </div>
        </div>
      )}
    </section>
  )
}

// Une promo sans date de fin ne se raconte pas en jours : elle court, point.
const promoLabel = (days) => {
  if (days == null) return 'en promo'
  if (days <= 0) return 'dernier jour !'
  return days === 1 ? 'encore 1 jour' : `encore ${days} jours`
}

const omit = (obj, key) => Object.fromEntries(Object.entries(obj).filter(([k]) => k !== key))

function CosmeticGrid({ list, diamonds, onBuy, onTry, tried, season = false }) {
  return (
    <div className="shop-grid">
      {list.map((c) => {
        const on = tried[c.slot]?.id === c.id
        return (
          <div key={c.id} className={`shop-cos rar-tint rar-${c.rarity} ${season ? 'season' : ''} ${on ? 'trying' : ''}`}>
            {season && c.days_left != null && <span className="shop-cos-left">⏳ {daysLabel(c.days_left)}</span>}
            {/* Toute la vignette est le bouton d'essayage : c'est le geste le plus fréquent. */}
            <button type="button" className="shop-cos-try" onClick={() => onTry(c)}
                    aria-pressed={on} title={on ? 'Retirer de l\'essai' : `Essayer ${c.name}`}>
              <CosmeticIcon art={c.art} emoji={c.emoji} className="shop-cos-emoji" />
              <span className="shop-cos-name">{c.name}</span>
              <span className="rar-pill">{rarityLabel(c.rarity)}</span>
            </button>
            {c.owned ? (
              <Link href="/sac?tab=wardrobe" className="shop-owned">{c.equipped ? '✓ Équipé' : 'Dans l\'armoire'}</Link>
            ) : (
              <button className="shop-buy full" disabled={diamonds < c.price} onClick={() => onBuy(c)}>
                {c.full_price && <s className="shop-was">{c.full_price}</s>}
                {c.price} 💎
              </button>
            )}
          </div>
        )
      })}
    </div>
  )
}
