import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Package, Search, XCircle } from 'lucide-react';
import { useState } from 'react';
import api, { mediaUrl, formatCFA } from '@/lib/api';
import { Commande, StatutCommande } from '@/types';
import toast from 'react-hot-toast';

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
  en_attente: 'En attente',
  validee: 'Validée',
  en_preparation: 'En préparation',
  expediee: 'Expédiée',
  livree: 'Livrée',
  rejetee: 'Rejetée',
  annulee: 'Annulée',
};

export default function CommandesPage() {
  const qc = useQueryClient();
  const [searchInput, setSearchInput] = useState('');

  const { data, isLoading } = useQuery({
    queryKey: ['commandes'],
    queryFn: () => api.get('/commandes/').then(r => r.data),
  });

  const commandes: Commande[] = data?.results || data || [];

  const annulerMutation = useMutation({
    mutationFn: (id: number) => api.post(`/commandes/${id}/annuler/`),
    onSuccess: () => { toast.success('Commande annulée'); qc.invalidateQueries({ queryKey: ['commandes'] }); },
    onError: () => toast.error("Erreur lors de l'annulation"),
  });

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const filtered = (commandes as any[]).filter((c: any) =>
    !searchInput ||
    c.monture_detail?.nom?.toLowerCase().includes(searchInput.toLowerCase())
  );

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-2">Mes commandes</h1>
      <p className="text-gray-500 text-sm mb-6">{commandes.length} commande{commandes.length !== 1 ? 's' : ''}</p>

      <div className="card mb-6">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            value={searchInput}
            onChange={e => setSearchInput(e.target.value)}
            className="input-field pl-9"
            placeholder="Rechercher par numéro de suivi ou monture..."
          />
        </div>
      </div>

      {isLoading ? (
        <div className="space-y-4">{[...Array(3)].map((_, i) => <div key={i} className="h-28 bg-gray-200 animate-pulse rounded-2xl" />)}</div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <Package className="w-12 h-12 mx-auto mb-3 opacity-40" />
          <p>Aucune commande pour l'instant</p>
        </div>
      ) : (
        <div className="space-y-4">
          {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
          {(filtered as any[]).map((c: any) => {
            const monture = c.monture_detail;
            const imgSrc = monture?.image ? mediaUrl(monture.image) : null;
            const statut = c.statut || 'en_attente';

            return (
              <div key={c.id} className="card hover:shadow-md transition-shadow">
                <div className="flex flex-col sm:flex-row sm:items-center gap-4">
                  {imgSrc ? (
                    <img src={imgSrc} alt={monture?.nom} loading="lazy" className="w-16 h-16 object-cover rounded-xl flex-shrink-0" />
                  ) : (
                    <div className="w-16 h-16 bg-gray-100 rounded-xl flex items-center justify-center flex-shrink-0">
                      <Package className="w-7 h-7 text-gray-300" />
                    </div>
                  )}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2 mb-1">
                      <h3 className="font-semibold text-gray-900">{monture?.nom || 'Monture'} <span className="text-gray-400 font-normal text-sm">{monture?.marque}</span></h3>
                      <span className={`badge flex-shrink-0 ${statutColors[statut] || 'bg-gray-100 text-gray-700'}`}>{statutLabels[statut] || statut}</span>
                    </div>
                    <div className="flex flex-wrap gap-3 text-sm">
                      <span className="text-gray-600">Total: <strong>{formatCFA(c.prix_total)}</strong></span>
                    </div>
                  </div>
                  <div className="flex flex-col items-end gap-2">
                    <div className="text-xs text-gray-400">
                      {c.date_commande ? new Date(c.date_commande).toLocaleDateString('fr-FR') : ''}
                    </div>
                    {statut === 'en_attente' && (
                      <button
                        onClick={() => annulerMutation.mutate(c.id)}
                        disabled={annulerMutation.isPending}
                        className="flex items-center gap-1 text-red-500 hover:text-red-700 text-xs"
                      >
                        <XCircle className="w-3.5 h-3.5" /> Annuler
                      </button>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
