import { Head, Link, useForm } from '@inertiajs/react'
import { csrf } from '../../lib/csrf'
import Flash from '../../components/Flash'

export default function Login() {
  const form = useForm({ email: '', password: '', authenticity_token: csrf() })
  const submit = (e) => { e.preventDefault(); form.post('/login') }

  return (
    <div className="auth-wrap">
      <Head title="Connexion" />
      <div className="auth-card">
        <div className="logo">🍑</div>
        <h1>Bouge Ton Boule</h1>
        <p className="sub">Connecte-toi pour rejoindre la bataille</p>

        <Flash />

        <form onSubmit={submit}>
          <input className="field" type="email" placeholder="Email" autoComplete="email" required
                 value={form.data.email} onChange={(e) => form.setData('email', e.target.value)} />
          <input className="field" type="password" placeholder="Mot de passe" autoComplete="current-password" required
                 value={form.data.password} onChange={(e) => form.setData('password', e.target.value)} />
          <button className="btn primary" type="submit" disabled={form.processing}>Se connecter</button>
        </form>

        <div className="or">— ou —</div>
        <form method="post" action="/auth/google_oauth2">
          <input type="hidden" name="authenticity_token" value={csrf()} />
          <button className="gbtn" type="submit">🇬 Continuer avec Google</button>
        </form>

        <p className="switch">Pas encore de compte ? <Link href="/register">Créer un compte</Link></p>
      </div>
    </div>
  )
}
