import { useEffect, useState } from 'react'

// Invite à installer la PWA. Trois cas :
// - déjà installée (mode standalone) ou déjà refusée (localStorage) → rien ;
// - iOS/Safari : pas d'installation automatique, on guide (Partager → écran d'accueil) —
//   indispensable : sur iPhone les notifications push n'arrivent qu'à l'app installée ;
// - Chrome/Android : on capture beforeinstallprompt et on propose un vrai bouton.
const DISMISS_KEY = 'btb-install-hint'

export default function InstallHint() {
  const [mode, setMode] = useState(null) // 'ios' | 'prompt' | null
  const [deferred, setDeferred] = useState(null)

  useEffect(() => {
    const standalone = window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone
    if (standalone || localStorage.getItem(DISMISS_KEY)) return

    const onPrompt = (e) => { e.preventDefault(); setDeferred(e); setMode('prompt') }
    window.addEventListener('beforeinstallprompt', onPrompt)
    if (/iphone|ipad|ipod/i.test(window.navigator.userAgent)) setMode('ios')
    return () => window.removeEventListener('beforeinstallprompt', onPrompt)
  }, [])

  if (!mode) return null

  const dismiss = () => { localStorage.setItem(DISMISS_KEY, '1'); setMode(null) }
  const install = async () => { deferred?.prompt(); await deferred?.userChoice; dismiss() }

  return (
    <div className="install-hint">
      <span className="ih-icon">🍑</span>
      <div className="ih-text">
        {mode === 'ios' ? (
          <>Installe l'app pour recevoir les notifications : <b>Partager</b> <span aria-hidden>⬆️</span> puis <b>« Sur l'écran d'accueil »</b>.</>
        ) : (
          <>Installe Bouge Ton Boule sur ton téléphone pour ne rien rater.</>
        )}
      </div>
      {mode === 'prompt' && <button className="ih-btn" onClick={install}>Installer</button>}
      <button className="ih-close" onClick={dismiss} aria-label="Ne plus afficher">✕</button>
    </div>
  )
}
