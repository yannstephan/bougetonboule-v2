// Jeton CSRF posé par Rails dans le <head>. Les formulaires Inertia doivent l'inclure dans
// leurs données (voir CLAUDE.md § Conventions).
export const csrf = () =>
  (typeof document !== 'undefined' && document.querySelector('meta[name=csrf-token]')?.content) || ''
