import { useQuery } from '@tanstack/react-query';
import { Package, ShoppingBag, TrendingUp, Clock } from 'lucide-react';
import api, { formatCFA } from '@/lib/api';

const statutColors: Record<string, string> = {
  en_attente: 'bg-yellow-100 text-yellow-700',
  validee: 'bg-blue-100 text-blue-700',
  en_preparation: 'bg-purple-100 text-purple-700',
  expediee: 'bg-indigo-100 text-indigo-700',
  livree: 'bg-green-100 text-green-700',
  rejetee: 'bg-red-100 text-red-700',
  annulee: 'bg-gray-100 text-gray-700',
};
const statutLabels: Record<string, string> = {
  en_attente: 'En attente', validee: 'Validée', en_preparation: 'En préparation',
  expediee: 'Expédiée', livree: 'Livrée', rejetee: 'Rejetée', annulee: 'Annulée',
};

export default function OpticienDashboard() {
  const { data: statsData } = useQuery({
    queryKey: ['stats-dashboard'],
    queryFn: () => api.get('/stats/dashboard/').then(r => r.data),
  });

  const { data: commandesData } = useQuery({
    queryKey: ['opticien-commandes'],
    queryFn: () => api.get('/commandes/').then(r => r.data),
  });

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const commandes: any[] = Array.isArray(commandesData) ? commandesData : (commandesData?.results || []);
  const pending = commandes.filter(c => c.statut === 'en_attente').length;
  const revenue = commandes.filter(c => c.statut === 'livree').reduce((s: number, c: any) => s + Number(c.prix_total), 0);

  const stats = [
    { icon: ShoppingBag, label: 'Total commandes', value: commandes.length, color: 'text-blue-600 bg-blue-100' },
    { icon: Clock, label: 'En attente', value: pending, color: 'text-yellow-600 bg-yellow-100' },
    { icon: Package, label: 'Montures', value: statsData?.total_montures ?? '—', color: 'text-purple-600 bg-purple-100' },
    { icon: TrendingUp, label: 'CA (livré)', value: formatCFA(statsData?.chiffre_affaires ?? revenue), color: 'text-green-600 bg-green-100' },
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Tableau de bord</h1>
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {stats.map(({ icon: Icon, label, value, color }) => (
          <div key={label} className="card">
            <div className={`w-10 h-10 rounded-xl flex items-center justify-center mb-3 ${color}`}>
              <Icon className="w-5 h-5" />
            </div>
            <div className="text-2xl font-bold text-gray-900">{value}</div>
            <div className="text-sm text-gray-500">{label}</div>
          </div>
        ))}
      </div>

      <div className="card">
        <h2 className="font-semibold text-gray-900 mb-4">Dernières commandes</h2>
        {commandes.length === 0 ? (
          <p className="text-gray-400 text-sm text-center py-6">Aucune commande</p>
        ) : (
          <div className="space-y-3">
            {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
            {commandes.slice(0, 5).map((c: any) => {
              const statut = c.statut || 'en_attente';
              return (
                <div key={c.id} className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                  <div className="flex-1 min-w-0">
                    <div className="font-medium text-sm truncate">{c.client_nom || 'Client'}</div>
                    <div className="text-xs text-gray-400">
                      {c.monture_detail?.nom} — {formatCFA(c.prix_total)}
                    </div>
                  </div>
                  <span className={`badge flex-shrink-0 ${statutColors[statut] || 'bg-gray-100 text-gray-700'}`}>
                    {statutLabels[statut] || statut}
                  </span>
                  <div className="text-xs text-gray-400">
                    {c.date_commande ? new Date(c.date_commande).toLocaleDateString('fr-FR') : ''}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
