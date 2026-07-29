import { Link } from '@inertiajs/react'

// Barre de titre des écrans secondaires : une flèche de retour, un titre, et ce qu'on veut
// à droite (le porte-monnaie, le multiplicateur de meute…).
export default function SubHeader({ title, back = '/', children }) {
  return (
    <div className="subhead">
      <Link href={back} className="back">←</Link>
      <div className="ti">{title}</div>
      {children}
    </div>
  )
}
