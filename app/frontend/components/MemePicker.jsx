import { useEffect, useRef, useState } from 'react'
import { router } from '@inertiajs/react'

// Recherche de GIF pour le chat (Giphy). On ne peut PAS envoyer une image quelconque : seules
// les URL des sources connues passent, et le serveur revérifie l'hôte.
// ⚠️ Le vocabulaire côté JOUEUR dit « GIF » ; le code garde `meme_*` — renommer une colonne
// et six fichiers pour un mot ne vaut pas la migration.
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
        <div className="tp-title">Ajouter un GIF</div>

        <input className="field" autoFocus value={q} placeholder="Chercher un GIF… (bravo, course, fatigué)"
               onChange={(e) => setQ(e.target.value)} />

        <div className="meme-grid">
          {loading && memes.length === 0 && <p className="meme-hint">Recherche…</p>}
          {!loading && memes.length === 0 && (
            <p className="meme-hint">
              Rien pour « {q} ». Essaie un autre mot, ou vide le champ pour voir les GIF
              du moment.
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
