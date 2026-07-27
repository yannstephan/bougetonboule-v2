import { Head, Link, router, useForm } from '@inertiajs/react'
import { useEffect, useRef, useState } from 'react'
import PlayerAvatar from '../components/PlayerAvatar'

const csrf = () =>
  (typeof document !== 'undefined' && document.querySelector('meta[name=csrf-token]')?.content) || ''

export default function Chat({ conversations }) {
  const [active, setActive] = useState(0)
  const conv = conversations[active]
  const scrollRef = useRef(null)
  const form = useForm({ body: '', authenticity_token: csrf() })

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

  return (
    <div className="shell">
      <Head title="Chat" />
      <div className="subhead">
        <Link href="/" className="back">←</Link>
        <div className="ti">💬 Chat</div>
      </div>

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
        <button className="send" type="submit" disabled={form.processing}>➤</button>
      </form>
    </div>
  )
}

function Message({ msg, prev }) {
  const newDay = prev?.day_label !== msg.day_label

  return (
    <>
      {newDay && <div className="chat-day">{msg.day_label}</div>}
      <div className={`msg ${msg.mine ? 'me' : ''}`}>
        <Link href={`/joueurs/${msg.membership_id}`}><PlayerAvatar avatar={msg.avatar} size={30} /></Link>
        <div className="msg-body">
          <span className="who">
            <Link href={`/joueurs/${msg.membership_id}`} className="who-link">{msg.mine ? 'Toi' : msg.author}</Link>
            <i style={{ color: msg.team.color }}>{msg.team.name}</i>
          </span>
          <div className="bub">{msg.body}</div>
          <span className="tm" title={`${msg.on} à ${msg.at}`}>{msg.on} · {msg.at}</span>
        </div>
      </div>
    </>
  )
}
