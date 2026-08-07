import { Head, Link, router, useForm } from '@inertiajs/react'
import { useEffect, useRef, useState } from 'react'
import PlayerAvatar from '../components/PlayerAvatar'
import Hud from '../components/Hud'
import BottomNav from '../components/BottomNav'
import MemePicker from '../components/MemePicker'

const csrf = () =>
  (typeof document !== 'undefined' && document.querySelector('meta[name=csrf-token]')?.content) || ''

export default function Chat({ conversations, memes }) {
  const [active, setActive] = useState(0)
  const conv = conversations[active]
  const scrollRef = useRef(null)
  const form = useForm({ body: '', authenticity_token: csrf() })
  const [picking, setPicking] = useState(false)

  useEffect(() => {
    const id = setInterval(
      () => router.reload({ only: ['conversations'], preserveState: true, preserveScroll: true }),
      8000
    )
    return () => clearInterval(id)
  }, [])

  useEffect(() => { scrollRef.current?.scrollTo(0, 1e7) }, [conversations, active])

  const send = (e) => {
    e.preventDefault()
    if (!form.data.body.trim() || form.processing) return
    // `form.transform()` ne retourne pas le formulaire : on ne peut pas chaîner .post() dessus.
    form.transform((d) => ({ body: d.body, authenticity_token: csrf() }))
    form.post(`/conversations/${conv.id}/messages`, {
      preserveState: true,
      preserveScroll: true,
      onSuccess: () => form.setData('body', ''),
    })
  }

  // Un meme part seul, sans passer par le champ texte : c'est une réaction, pas une légende.
  const sendMeme = (meme) => {
    setPicking(false)
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
          <button key={c.id} className={`chat-tab ${i === active ? 'on' : ''}`} onClick={() => setActive(i)}>
            {c.kind === 'team' ? '🛡️ ' : '🌍 '}{c.label}
          </button>
        ))}
      </div>

      <div className="chat-scroll" ref={scrollRef}>
        {conv?.messages?.length
          ? conv.messages.map((msg, i) => (
              <Message key={msg.id} msg={msg} prev={conv.messages[i - 1]} />
            ))
          : <div className="chat-empty">Aucun message. Lance la discussion !</div>}
      </div>

      <form className="chat-input" onSubmit={send}>
        <input className="field" placeholder="Ton message…" value={form.data.body}
               onChange={(e) => form.setData('body', e.target.value)} />
        {/* Le « + » du composeur : la porte des memes. Toujours là — la source sans clé
            (Imgflip) prend le relais quand Giphy n'est pas configuré, donc il n'y a jamais
            de bouton qui n'ouvre rien. */}
        <button className="meme-btn" type="button" onClick={() => setPicking(true)}
                title="Ajouter un meme" aria-label="Ajouter un meme">+</button>
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
