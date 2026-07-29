import { usePage } from '@inertiajs/react'

// Le message flash du serveur (notice en vert, alert en rouge). Rien à afficher = rien.
export default function Flash({ inset = false }) {
  const { flash } = usePage().props
  if (!flash?.notice && !flash?.alert) return null

  const style = inset ? { margin: '10px 14px 0' } : undefined
  return (
    <>
      {flash.notice && <div className="flash ok" style={style}>{flash.notice}</div>}
      {flash.alert && <div className="flash err" style={style}>{flash.alert}</div>}
    </>
  )
}
