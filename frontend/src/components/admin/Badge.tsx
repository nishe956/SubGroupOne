import { ReactNode } from 'react';

export type Ton = 'succes' | 'attente' | 'info' | 'danger' | 'accent' | 'neutre';

/**
 * Pastilles de statut du back-office.
 *
 * Fond très clair + texte saturé + liseré intérieur : le badge reste lisible
 * aussi bien sur une ligne blanche que sur une ligne zébrée, sans jamais
 * peser autant qu'un bouton.
 */
const TONS: Record<Ton, string> = {
  succes:  'bg-emerald-50 text-emerald-700 ring-emerald-600/20',
  attente: 'bg-amber-50   text-amber-700   ring-amber-600/20',
  info:    'bg-blue-50    text-blue-700    ring-blue-600/20',
  danger:  'bg-red-50     text-red-700     ring-red-600/20',
  accent:  'bg-accent-50  text-accent-700  ring-accent-600/20',
  neutre:  'bg-gray-100   text-gray-600    ring-gray-500/20',
};

export default function Badge({ ton = 'neutre', children, className = '' }: {
  ton?: Ton; children: ReactNode; className?: string;
}) {
  return (
    <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset ${TONS[ton]} ${className}`}>
      {children}
    </span>
  );
}

const STATUTS_COMMANDE: Record<string, { libelle: string; ton: Ton }> = {
  en_attente:     { libelle: 'En attente',     ton: 'attente' },
  validee:        { libelle: 'Validée',        ton: 'info'    },
  en_preparation: { libelle: 'En préparation', ton: 'accent'  },
  livree:         { libelle: 'Livrée',         ton: 'succes'  },
  rejetee:        { libelle: 'Rejetée',        ton: 'danger'  },
  annulee:        { libelle: 'Annulée',        ton: 'neutre'  },
};

/** Traduit un statut de commande de l'API en libellé + ton d'affichage. */
export function statutCommande(statut: string) {
  return STATUTS_COMMANDE[statut] ?? { libelle: statut.replace(/_/g, ' '), ton: 'neutre' as Ton };
}
