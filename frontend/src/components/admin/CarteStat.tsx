import { LucideIcon, TrendingUp, TrendingDown } from 'lucide-react';
import Carte from './Carte';
import Badge from './Badge';

export type Teinte = 'accent' | 'bleu' | 'emeraude' | 'violet' | 'ambre';

/** Pastille d'icône : fond très clair de la teinte, trait saturé. */
const TEINTES: Record<Teinte, string> = {
  accent:   'bg-accent-50 text-accent-600',
  bleu:     'bg-blue-50 text-blue-600',
  emeraude: 'bg-emerald-50 text-emerald-600',
  violet:   'bg-violet-50 text-violet-600',
  ambre:    'bg-amber-50 text-amber-600',
};

export default function CarteStat({ libelle, valeur, icone: Icone, teinte = 'accent', variation, detail }: {
  libelle: string;
  valeur: string;
  icone: LucideIcon;
  teinte?: Teinte;
  /** Évolution en %, ou `null` s'il n'existe aucune période de comparaison. */
  variation?: number | null;
  /** Ligne secondaire factuelle (« 12 ce mois-ci »). */
  detail?: string;
}) {
  // Un montant en F CFA est bien plus long qu'un compteur : on descend d'un
  // cran de taille plutôt que de le laisser déborder ou le tronquer.
  const tailleValeur = valeur.length > 11 ? 'text-xl' : 'text-3xl';

  return (
    <Carte className="flex flex-col">
      <div className="flex items-start justify-between gap-2 mb-5">
        <div className={`w-11 h-11 rounded-full flex items-center justify-center ${TEINTES[teinte]}`}>
          <Icone className="w-5 h-5" strokeWidth={1.75} />
        </div>
        {variation !== null && variation !== undefined && (
          <Badge ton={variation >= 0 ? 'succes' : 'danger'}>
            {variation >= 0 ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
            {variation >= 0 ? '+' : ''}{variation} %
          </Badge>
        )}
      </div>
      <div className="text-sm text-gray-500">{libelle}</div>
      <div className={`${tailleValeur} font-bold tracking-tight text-gray-900 leading-tight mt-0.5`}>{valeur}</div>
      {detail && <div className="text-xs text-gray-400 mt-1.5">{detail}</div>}
    </Carte>
  );
}
