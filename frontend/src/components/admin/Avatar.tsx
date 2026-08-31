/** Teintes d'avatar : choisies par hachage du nom, donc stables d'un rendu à l'autre. */
const TEINTES = [
  'bg-accent-100 text-accent-700',
  'bg-blue-100 text-blue-700',
  'bg-emerald-100 text-emerald-700',
  'bg-violet-100 text-violet-700',
  'bg-amber-100 text-amber-700',
];

const TAILLES = {
  sm: 'w-8 h-8 text-[11px]',
  md: 'w-9 h-9 text-xs',
  lg: 'w-11 h-11 text-sm',
};

/** Pastille d'initiales : le projet ne stocke pas de photo de profil. */
export default function Avatar({ nom, taille = 'md' }: { nom: string; taille?: keyof typeof TAILLES }) {
  const propre = nom.trim() || '?';
  const initiales = propre
    .split(/\s+/)
    .slice(0, 2)
    .map(mot => mot[0]?.toUpperCase() ?? '')
    .join('');

  const somme = [...propre].reduce((total, caractere) => total + caractere.charCodeAt(0), 0);

  return (
    <span
      aria-hidden="true"
      className={`inline-flex items-center justify-center rounded-full font-semibold flex-shrink-0 ${TAILLES[taille]} ${TEINTES[somme % TEINTES.length]}`}
    >
      {initiales || '?'}
    </span>
  );
}
