import { Head, Link, router, useForm, usePage } from '@inertiajs/react'
import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react'
import PlayerAvatar from '../components/PlayerAvatar'
import Hud from '../components/Hud'
import BottomNav from '../components/BottomNav'
import MemePicker from '../components/MemePicker'

const csrf = () =>
  (typeof document !== 'undefined' && document.querySelector('meta[name=csrf-token]')?.content) || ''

// On ne garde jamais deux fois le même message, et on les range dans l'ordre du serveur
// (created_at puis id). C'est ce tri, et lui seul, qui recolle une page ancienne devant le fil.
const merge = (a, b) => {
  const by = new Map()
  for (const m of [...a, ...b]) by.set(m.id, m)
  return [...by.values()].sort((x, y) => x.ts - y.ts || x.id - y.id)
}

// À moins de ça du bas, on considère que le joueur suit la conversation en direct : un message
// qui arrive le pousse. Plus haut, il lit — et rien ne doit lui reprendre son défilement.
const NEAR_BOTTOM = 120

export default function Chat({ conversations, memes, active_kind: activeKind }) {
  // ⚠️ Le canal ouvert vit dans l'URL, pas dans un état local : c'est le serveur qui décide
  // ce qui est LU, et il ne peut le savoir que si on le lui dit. Changer d'onglet est donc
  // une visite (`?canal=…`), comme l'onglet du sac ou de la boutique.
  const active = Math.max(0, conversations.findIndex((c) => c.kind === activeKind))
  const conv = conversations[active]
  const openTab = (kind) => router.get('/chat', { canal: kind }, { preserveScroll: false })
  const scrollRef = useRef(null)
  const form = useForm({ body: '', authenticity_token: csrf() })
  const [picking, setPicking] = useState(false)

  // Le serveur ne sert que la DERNIÈRE page ; les pages d'avant s'empilent ici. On ne jette
  // jamais rien : la fenêtre du serveur glisse d'un cran à chaque message reçu, donc si on ne
  // gardait que sa dernière réponse, le message qui en sort laisserait un trou dans le fil.
  const [pool, setPool] = useState(conv?.messages || [])
  const [older, setOlder] = useState({ more: !!conv?.has_more, loading: false })
  const consumed = useRef(null)
  const olderProp = usePage().props.older

  // Deux besoins opposés dans le même conteneur : coller au bas quand un message arrive, et
  // NE PAS bouger d'un pixel quand on greffe une page devant. On mémorise donc la distance au
  // bas avant de charger ; la restaurer revient à ancrer la vue sur le message qu'on lisait.
  const stick = useRef(true)
  const anchor = useRef(null)

  // ⚠️ Le verrou est une `ref`, pas l'état `loading` : le défilement tire des dizaines
  // d'événements par seconde et ils partagent tous le même rendu, donc la même valeur de
  // `loading`. Une ref se referme dans l'instant, avant même le rendu suivant.
  const busy = useRef(false)

  useEffect(() => {
    setPool(conv?.messages || [])
    setOlder({ more: !!conv?.has_more, loading: false })
    consumed.current = null
    busy.current = false
    stick.current = true
  }, [activeKind])

  useEffect(() => {
    if (conv?.messages?.length) setPool((p) => merge(p, conv.messages))
  }, [conv?.messages])

  // La page d'avant arrive dans SA propre prop, réclamée en rechargement partiel. Le garde
  // `consumed` évite de la réappliquer quand une autre visite (sondage, envoi) repasse par là
  // avec le même `?avant=` resté dans l'URL.
  useEffect(() => {
    if (!olderProp || consumed.current === olderProp.before) return
    consumed.current = olderProp.before
    setPool((p) => merge(p, olderProp.messages))
    setOlder({ more: olderProp.has_more, loading: false })
  }, [olderProp])

  const loadOlder = useCallback(() => {
    const el = scrollRef.current
    if (!el || !older.more || busy.current || !pool.length) return
    busy.current = true
    anchor.current = el.scrollHeight - el.scrollTop
    setOlder((o) => ({ ...o, loading: true }))
    router.reload({
      only: ['older'],
      data: { canal: activeKind, avant: pool[0].id },
      preserveState: true,
      preserveScroll: true,
      replace: true,
      onFinish: () => { busy.current = false; setOlder((o) => ({ ...o, loading: false })) },
    })
  }, [older.more, pool, activeKind])

  const onScroll = () => {
    const el = scrollRef.current
    if (!el) return
    stick.current = el.scrollHeight - el.scrollTop - el.clientHeight < NEAR_BOTTOM
    if (el.scrollTop < 60) loadOlder()
  }

  useLayoutEffect(() => {
    const el = scrollRef.current
    if (!el) return
    if (anchor.current != null) {
      el.scrollTop = el.scrollHeight - anchor.current // greffe devant : la vue ne bouge pas
      anchor.current = null
    } else if (stick.current) {
      el.scrollTop = el.scrollHeight
    }
  }, [pool])

  useEffect(() => {
    const id = setInterval(
      () => router.reload({ only: ['conversations'], preserveState: true, preserveScroll: true }),
      8000
    )
    return () => clearInterval(id)
  }, [])

  // Le sondage garde l'URL, donc son `?canal=` : chaque tour marque lu le canal ouvert et
  // rafraîchit la pastille de l'AUTRE. On voit arriver les messages d'à côté sans bouger.

  const send = (e) => {
    e.preventDefault()
    if (!form.data.body.trim() || form.processing) return
    stick.current = true // on écrit : on veut voir son propre message arriver
    // `form.transform()` ne retourne pas le formulaire : on ne peut pas chaîner .post() dessus.
    form.transform((d) => ({ body: d.body, authenticity_token: csrf() }))
    form.post(`/conversations/${conv.id}/messages`, {
      preserveState: true,
      preserveScroll: true,
      onSuccess: () => form.setData('body', ''),
    })
  }

  // Un GIF part seul, sans passer par le champ texte : c'est une réaction, pas une légende.
  const sendMeme = (meme) => {
    setPicking(false)
    stick.current = true
    router.post(`/conversations/${conv.id}/messages`,
      { meme_url: meme.url, meme_title: meme.title, authenticity_token: csrf() },
      { preserveState: true, preserveScroll: true })
  }

  return (
    <div className="shell chat-shell">
      <Head title="Chat" />
      <Hud />

      <div className="chat-tabs">
        {conversations.map((c, i) => (
          <button key={c.id} className={`chat-tab ${i === active ? 'on' : ''}`}
                  onClick={() => openTab(c.kind)}>
            {c.kind === 'team' ? '🛡️ ' : '🌍 '}{c.label}
            {c.unread > 0 && <span className="chat-tab-b">{c.unread > 99 ? '99+' : c.unread}</span>}
          </button>
        ))}
      </div>

      <div className="chat-scroll" ref={scrollRef} onScroll={onScroll}>
        {/* Le haut du fil dit toujours où l'on en est : il reste de l'historique, il arrive,
            ou on est au tout premier message. Sans ça, remonter donne l'impression que la
            conversation commence là. Le bouton double le défilement — au clavier, à la
            souris, ou quand l'élan du doigt s'arrête juste avant le déclencheur. */}
        {older.loading && <div className="chat-more">Chargement…</div>}
        {!older.loading && older.more && (
          <button type="button" className="chat-more chat-more-btn" onClick={loadOlder}>
            Messages plus anciens
          </button>
        )}
        {!older.more && pool.length > 0 && (
          <div className="chat-more">Début de la conversation</div>
        )}

        {pool.length
          ? pool.map((msg, i) => <Message key={msg.id} msg={msg} prev={pool[i - 1]} />)
          : <div className="chat-empty">Aucun message. Lance la discussion !</div>}
      </div>

      <form className="chat-input" onSubmit={send}>
        <input className="field" placeholder="Ton message…" value={form.data.body}
               onChange={(e) => form.setData('body', e.target.value)} />
        {/* Le « + » du composeur : la porte des memes. Toujours là — la source sans clé
            (Imgflip) prend le relais quand Giphy n'est pas configuré, donc il n'y a jamais
            de bouton qui n'ouvre rien. */}
        <button className="meme-btn" type="button" onClick={() => setPicking(true)}
                title="Ajouter un GIF" aria-label="Ajouter un GIF">+</button>
        <button className="send" type="submit" disabled={form.processing}>➤</button>
      </form>

      {picking && <MemePicker memes={memes} onPick={sendMeme} onClose={() => setPicking(false)} />}
      <BottomNav />
    </div>
  )
}

function Message({ msg, prev }) {
  const newDay = prev?.day_label !== msg.day_label

  return (
    <>
      {newDay && <div className="chat-day">{msg.day_label}</div>}
      <div className={`msg ${msg.mine ? 'me' : ''}`}>
        <Link href={`/joueurs/${msg.membership_id}`}><PlayerAvatar avatar={msg.avatar} size={40} /></Link>
        <div className="msg-body">
          <span className="who">
            <Link href={`/joueurs/${msg.membership_id}`} className="who-link">{msg.mine ? 'Toi' : msg.author}</Link>
            <i style={{ color: msg.team.color }}>{msg.team.name}</i>
          </span>
          <div className={`bub ${msg.meme_url && !msg.body ? 'meme-only' : ''}`}>
            {msg.meme_url && (
              <img className="msg-meme" src={msg.meme_url} alt={msg.meme_title || 'meme'} loading="lazy" />
            )}
            {msg.body}
          </div>
          <span className="tm" title={`${msg.on} à ${msg.at}`}>{msg.on} · {msg.at}</span>
        </div>
      </div>
    </>
  )
}
