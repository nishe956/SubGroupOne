import { ResponsiveContainer, AreaChart, Area, ReferenceLine, XAxis, YAxis, CartesianGrid, Tooltip } from 'recharts';
import { TrendingUp, TrendingDown } from 'lucide-react';
import { formatCFA } from '@/lib/api';
import Carte, { EnTeteCarte } from './Carte';

export interface PointRevenu { mois: string; total: number; clients: number }

/** Abrège les montants de l'axe : « 1 250 000 F CFA » y serait illisible. */
function formatCourt(valeur: number): string {
  if (valeur >= 1_000_000) return `${(valeur / 1_000_000).toFixed(valeur >= 10_000_000 ? 0 : 1).replace('.', ',')} M`;
  if (valeur >= 1_000) return `${Math.round(valeur / 1_000)} k`;
  return String(valeur);
}

/**
 * Infobulle : le montant du mois, et son écart avec le mois précédent. Cet
 * écart est la seule chose que la courbe ne dit pas déjà à elle seule.
 */
function Infobulle({ active, payload, label, points }: any) {
  if (!active || !payload?.length) return null;
  const valeur: number = payload[0].value;
  const index = points.findIndex((p: PointRevenu) => p.mois === label);
  const precedent = index > 0 ? points[index - 1].total : null;
  const ecart = precedent && precedent > 0 ? Math.round(((valeur - precedent) / precedent) * 100) : null;

  return (
    <div className="rounded-xl bg-white px-3.5 py-2.5 shadow-lg border border-gray-100">
      <div className="text-[11px] text-gray-400 capitalize">{label}</div>
      <div className="font-bold text-gray-900 mt-0.5">{formatCFA(valeur)}</div>
      {ecart !== null && (
        <div className={`inline-flex items-center gap-1 mt-1.5 rounded-md px-1.5 py-0.5 text-[11px] font-medium ${
          ecart >= 0 ? 'bg-emerald-50 text-emerald-700' : 'bg-red-50 text-red-700'
        }`}>
          {ecart >= 0 ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
          {ecart >= 0 ? '+' : ''}{ecart} %
        </div>
      )}
    </div>
  );
}

export default function CourbeRevenus({ points }: { points: PointRevenu[] }) {
  // Référence horizontale : la moyenne réellement observée sur la période.
  // Elle situe chaque mois sans inventer d'objectif commercial.
  const moyenne = points.length
    ? points.reduce((somme, p) => somme + p.total, 0) / points.length
    : 0;

  return (
    <Carte>
      <EnTeteCarte
        titre="Revenus mensuels"
        sousTitre="Commandes livrées sur les 6 derniers mois"
        action={
          <div className="flex items-center gap-4 text-xs text-gray-500">
            <span className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-accent-500" /> Revenus
            </span>
            <span className="flex items-center gap-1.5">
              <span className="w-4 border-t-2 border-dashed border-gray-300" /> Moyenne
            </span>
          </div>
        }
      />

      <div className="h-[280px] -ml-2">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={points} margin={{ top: 8, right: 8, bottom: 0, left: 0 }}>
            <defs>
              <linearGradient id="degradeRevenus" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#f26b21" stopOpacity={0.28} />
                <stop offset="100%" stopColor="#f26b21" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 4" stroke="#eef0f2" />
            <XAxis
              dataKey="mois"
              axisLine={{ stroke: '#e5e7eb' }}
              tickLine={false}
              tick={{ fill: '#9ca3af', fontSize: 11 }}
              dy={6}
            />
            <YAxis
              axisLine={false}
              tickLine={false}
              tick={{ fill: '#9ca3af', fontSize: 11 }}
              tickFormatter={formatCourt}
              width={52}
            />
            <Tooltip content={<Infobulle points={points} />} cursor={{ stroke: '#fecdb2', strokeWidth: 1 }} />
            <ReferenceLine y={moyenne} stroke="#cbd5e1" strokeDasharray="6 5" />
            <Area
              type="monotone"
              dataKey="total"
              name="Revenus"
              stroke="#f26b21"
              strokeWidth={2.5}
              fill="url(#degradeRevenus)"
              dot={{ r: 3, fill: '#f26b21', strokeWidth: 0 }}
              activeDot={{ r: 5, fill: '#f26b21', stroke: '#fff', strokeWidth: 2 }}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </Carte>
  );
}
