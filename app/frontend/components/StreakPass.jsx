import { router } from '@inertiajs/react'

const csrf = () =>
  (typeof document !== 'undefined' && document.querySelector('meta[name=csrf-token]')?.content) || ''

// La série hebdo présentée comme une piste de season pass : cinq paliers, le gros lot au bout,
// et le cycle se rejoue. Les gains ne tombent plus tout seuls — le joueur vient les chercher.
//
// Le nœud du palier (5e) est plus gros que les autres : sur une piste, la récompense majeure
// se voit de loin, c'est elle qui donne envie d'aller au bout.
export default function StreakPass({ streak }) {
  if (!streak) return null

  const { weeks, best, jokers, joker_max: jokerMax, cycle, to_milestone: toGo, ran_this_week: ran, nodes } = streak
  const claimable = nodes.filter((n) => n.state === 'claimable')

  // On encaisse une SEMAINE : un palier pose deux gains (les 💎 et le cadeau), et ils
  // doivent partir ensemble.
  const claim = (week) =>
    router.post(`/serie/${week}/reclamer`, { authenticity_token: csrf() }, { preserveScroll: true })

  return (
    <section className={`pass ${claimable.length > 0 ? 'has-loot' : ''}`}>
      <header className="pass-head">
        <span className="pass-title">🔥 Série hebdo</span>
        <span className="pass-cycle">Palier {cycle}</span>
        <span className="pass-jokers" title={`Jokers : ${jokers} sur ${jokerMax}`}>
          {Array.from({ length: jokerMax }, (_, i) => (
            <i key={i} className={i < jokers ? 'on' : ''}>🧊</i>
          ))}
        </span>
      </header>

      <ol className="pass-track">
        {nodes.map((n) => (
          <li key={n.week} className={`pass-node ${n.state}${n.milestone ? ' milestone' : ''}`}>
            <span className="pass-dot">
              {n.state === 'claimed' && '✓'}
              {n.state === 'claimable' && '!'}
              {n.milestone && n.state !== 'claimed' && n.state !== 'claimable' && '🎁'}
            </span>
            {/* Le palier donne TROIS choses : la pastille porte le 🎁, l'étiquette le reste. */}
            <span className="pass-loot">{n.milestone ? `${n.diamonds}💎🧊` : `${n.diamonds}💎`}</span>
            <span className="pass-week">S{n.week}</span>
          </li>
        ))}
      </ol>

      {claimable.length > 0 ? (
        <div className="pass-claim">
          {claimable.map((n) => (
            <button key={n.week} type="button" className="btn primary" onClick={() => claim(n.week)}>
              🎉 Réclamer la semaine {n.week}{n.milestone ? ' + le cadeau 🎁' : ''}
            </button>
          ))}
        </div>
      ) : (
        <p className="pass-foot">
          {ran
            ? <><b>Semaine sécurisée ✅</b> — {footTail(toGo)}</>
            : <><b>Pas encore couru cette semaine.</b> Ta prochaine sortie débloque le palier tout de suite — {footTail(toGo)}</>}
          {best > weeks && <span className="pass-best"> · record {best}</span>}
        </p>
      )}
    </section>
  )
}

// Ce qu'il reste avant le gros lot, formulé pour donner envie d'y aller.
function footTail(toGo) {
  if (toGo <= 0) return 'le cadeau est au bout de celle-ci 🎁'
  if (toGo === 1) return 'plus qu’une semaine avant le cadeau 🎁'
  return `plus que ${toGo} semaines avant le cadeau 🎁`
}
