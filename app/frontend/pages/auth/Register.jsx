import { Head, Link, useForm } from '@inertiajs/react'
import { csrf } from '../../lib/csrf'
import Flash from '../../components/Flash'

export default function Register() {
  const form = useForm({ firstname: '', email: '', password: '', authenticity_token: csrf() })
  const submit = (e) => { e.preventDefault(); form.post('/register') }

  return (
    <div className="auth-wrap">
      <Head title="Créer un compte" />
      <div className="auth-card">
        <div className="logo">🍑</div>
        <h1>Rejoins le jeu</h1>
        <p className="sub">Transforme tes runs en batailles entre potes</p>

        <Flash />

        <form onSubmit={submit}>
          <input className="field" type="text" placeholder="Prénom" required
                 value={form.data.firstname} onChange={(e) => form.setData('firstname', e.target.value)} />
          <input className="field" type="email" placeholder="Email" autoComplete="email" required
                 value={form.data.email} onChange={(e) => form.setData('email', e.target.value)} />
          <input className="field" type="password" placeholder="Mot de passe (6+ caractères)" autoComplete="new-password" required
                 value={form.data.password} onChange={(e) => form.setData('password', e.target.value)} />
          <button className="btn primary" type="submit" disabled={form.processing}>Créer mon compte</button>
        </form>

        <div className="or">— ou —</div>
        <form method="post" action="/auth/google_oauth2">
          <input type="hidden" name="authenticity_token" value={csrf()} />
          <button className="gbtn" type="submit">🇬 Continuer avec Google</button>
        </form>

        <p className="switch">Déjà inscrit ? <Link href="/login">Se connecter</Link></p>
      </div>
    </div>
  )
}
