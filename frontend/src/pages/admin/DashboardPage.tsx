import { useQuery } from '@tanstack/react-query';
import { Users, Building2, ShoppingBag, Package, TrendingUp } from 'lucide-react';
import api, { formatCFA } from '@/lib/api';
import { DashboardStats } from '@/types';

export default function AdminDashboard() {
  const { data: stats, isLoading } = useQuery<DashboardStats>({
    queryKey: ['admin-stats'],
    queryFn: () => api.get('/stats/dashboard/').then(r => r.data),
  });

  if (isLoading) return (
    <div className="flex justify-center py-20">
      <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary-600" />
    </div>
  );

  const cards = [
    { icon: Users, label: 'Clients', value: stats?.total_clients ?? 0, color: 'text-blue-600 bg-blue-100' },
    { icon: Building2, label: 'Opticiens', value: stats?.total_opticiens ?? 0, color: 'text-purple-600 bg-purple-100' },
    { icon: ShoppingBag, label: 'Commandes', value: stats?.total_commandes ?? 0, color: 'text-orange-600 bg-orange-100' },
    { icon: Package, label: 'Montures', value: stats?.total_montures ?? 0, color: 'text-green-600 bg-green-100' },
    { icon: TrendingUp, label: 'CA total', value: formatCFA(stats?.chiffre_affaires ?? 0), color: 'text-emerald-600 bg-emerald-100' },
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-100 mb-6">Vue d'ensemble</h1>
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4 mb-8">
        {cards.map(({ icon: Icon, label, value, color }) => (
          <div key={label} className="bg-gray-800 rounded-2xl p-5">
            <div className={`w-10 h-10 rounded-xl flex items-center justify-center mb-3 ${color}`}>
              <Icon className="w-5 h-5" />
            </div>
            <div className="text-2xl font-bold text-white">{value}</div>
            <div className="text-sm text-gray-400">{label}</div>
          </div>
        ))}
      </div>

      {stats?.commandes_par_statut && Object.keys(stats.commandes_par_statut).length > 0 && (
        <div className="bg-gray-800 rounded-2xl p-6">
          <h2 className="font-semibold text-gray-100 mb-4">Commandes par statut</h2>
          <div className="space-y-2">
            {Object.entries(stats.commandes_par_statut).map(([statut, count]) => (
              <div key={statut} className="flex items-center justify-between">
                <span className="text-gray-400 text-sm">{statut.replace('_', ' ')}</span>
                <span className="font-medium text-white text-sm">{count}</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
