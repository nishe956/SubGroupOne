import { ReactNode } from 'react';

/**
 * Surface de base du back-office : blanc, coins largement arrondis, ombre
 * quasi imperceptible. Tout le contenu de l'admin vit dans une de ces cartes,
 * posée sur le gris clair de la page.
 */
export default function Carte({ children, className = '', padding = true }: {
  children: ReactNode; className?: string; padding?: boolean;
}) {
  return (
    <div className={`bg-white rounded-2xl border border-gray-100 shadow-card ${padding ? 'p-5 md:p-6' : ''} ${className}`}>
      {children}
    </div>
  );
}

/** En-tête d'une carte : titre à gauche, action facultative à droite. */
export function EnTeteCarte({ titre, sousTitre, action }: {
  titre: string; sousTitre?: string; action?: ReactNode;
}) {
  return (
    <div className="flex items-start justify-between gap-3 mb-5">
      <div>
        <h2 className="font-semibold text-gray-900">{titre}</h2>
        {sousTitre && <p className="text-xs text-gray-500 mt-0.5">{sousTitre}</p>}
      </div>
      {action && <div className="flex-shrink-0">{action}</div>}
    </div>
  );
}
