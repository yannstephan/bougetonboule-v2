import { useEffect, useRef, useState } from 'react'
import { router } from '@inertiajs/react'

// Recherche de memes pour le chat. On ne peut PAS envoyer une image quelconque : seuls les
// memes des catalogues passent, et le serveur revérifie l'hôte.
//
// ⚠️ La feuille s'ouvre sur un CATALOGUE À FEUILLETER, pas sur un champ vide. Sans clé Giphy,
// les sources libres sont petites et leurs titres sont en anglais : chercher « bébé » ou
// « patron » ne donnerait rien, alors que faire défiler marche toujours.
//
// La recherche passe par un rechargement partiel Inertia (`only: ['memes']`) plutôt qu'une
// API JSON à part — c'est la convention du projet. La frappe est temporisée : sans ça on
// tirerait une requête par lettre sur une API tierce.
export default function MemePicker({ memes = [], onPick, onClose }) {
  const [q, setQ] = useState('')
  const [loading, setLoading] = useState(false)
  const timer = useRef(null)
  const first = useRef(true)

  useEffect(() => {
    // À l'ouverture, les memes servis avec la page suffisent : pas de requête inutile.
    if (first.current) { first.current = false; return undefined }

    clearTimeout(timer.current)
    setLoading(true)
    timer.current = setTimeout(() => {
      router.reload({
        only: ['memes'],
        data: { meme_q: q },
        preserveState: true,
        preserveScroll: true,
        onFinish: () => setLoading(false),
      })
    }, 400)
    return () => clearTimeout(timer.current)
  }, [q])

  return (
    <div className="tp-backdrop" onClick={onClose}>
      <div className="tp-sheet meme-sheet" onClick={(e) => e.stopPropagation()}>
        <div className="tp-title">Ajouter un meme</div>

        <input className="field" autoFocus value={q} placeholder="Filtrer… (drake, cat, boss)"
               onChange={(e) => setQ(e.target.value)} />

        <div className="meme-grid">
          {loading && memes.length === 0 && <p className="meme-hint">Recherche…</p>}
          {!loading && memes.length === 0 && (
            <p className="meme-hint">
              Rien pour « {q} ». Les titres sont en anglais — essaie <b>cat</b>, <b>boss</b>,
              <b> drake</b>… ou vide le champ pour tout parcourir.
            </p>
          )}
          {memes.map((m) => (
            <button key={m.id} type="button" className="meme-cell" onClick={() => onPick(m)}
                    title={m.title}>
              <img src={m.preview} alt={m.title} loading="lazy" />
            </button>
          ))}
        </div>

        <button className="tp-cancel" onClick={onClose}>Fermer</button>
      </div>
    </div>
  )
}
