import { Head, Link, router, useForm } from '@inertiajs/react'
import { useEffect, useRef, useState } from 'react'

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
    if (!form.data.body.trim()) return
    form.transform((d) => ({ body: d.body, authenticity_token: csrf() }))
      .post(`/conversations/${conv.id}/messages`, {
        preserveState: true, preserveScroll: true,
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
        {conv?.messages?.length ? conv.messages.map((msg) => (
          <div key={msg.id} className={`msg ${msg.mine ? 'me' : ''}`}>
            {!msg.mine && <span className="who">{msg.author}</span>}
            <div className="bub">{msg.body}</div>
            <span className="tm">{msg.at}</span>
          </div>
        )) : <div className="chat-empty">Aucun message. Lance la discussion !</div>}
      </div>

      <form className="chat-input" onSubmit={send}>
        <input className="field" placeholder="Ton message…" value={form.data.body}
               onChange={(e) => form.setData('body', e.target.value)} />
        <button className="send" type="submit" disabled={form.processing}>➤</button>
      </form>
    </div>
  )
}
