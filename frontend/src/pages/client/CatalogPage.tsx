import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { Search, Filter, Camera, ShoppingCart } from 'lucide-react';
import api, { mediaUrl, formatCFA } from '@/lib/api';
import { Monture } from '@/types';

export default function CatalogPage() {
  const [filters, setFilters] = useState({
    search: '', categorie: '', forme: '', couleur: '',
    minPrix: '', maxPrix: '', page: '1',
  });

  const { data, isLoading } = useQuery({
    queryKey: ['montures', filters],
    queryFn: () => {
      const { minPrix, maxPrix, ...rest } = filters;
      const params: Record<string, string> = { ...rest };
      if (minPrix) params.prix_min = minPrix;
      if (maxPrix) params.prix_max = maxPrix;
      return api.get('/montures/', { params }).then(r => r.data);
    },
  });

  const montures: Monture[] = Array.isArray(data) ? data : (data?.results || data?.montures || []);
  const total: number = montures.length || data?.count || 0;
  const totalPages: number = data?.pages || Math.ceil(total / 12) || 1;

  const setFilter = (key: string, val: string) =>
    setFilters(f => ({ ...f, [key]: val, page: '1' }));

  const categorieOptions = [
    { val: 'adulte', label: 'Adulte' }, { val: 'enfant', label: 'Enfant' },
    { val: 'sport', label: 'Sport' }, { val: 'luxe', label: 'Luxe' },
  ];
  const formeOptions = [
    { val: 'ronde', label: 'Ronde' }, { val: 'carree', label: 'Carrée' },
    { val: 'rectangulaire', label: 'Rectangulaire' }, { val: 'ovale', label: 'Ovale' },
  ];
  const couleurOptions = ['Noir', 'Marron', 'Or', 'Argent', 'Bleu', 'Rouge', 'Écaille'];

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Catalogue</h1>
          <p className="text-gray-500 text-sm mt-1">{total} monture{total !== 1 ? 's' : ''} disponible{total !== 1 ? 's' : ''}</p>
        </div>
      </div>

      <div className="card mb-6">
        <div className="flex gap-3 flex-wrap">
          <div className="relative flex-1 min-w-48">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              value={filters.search}
              onChange={e => setFilter('search', e.target.value)}
              className="input-field pl-9"
              placeholder="Rechercher une monture..."
            />
          </div>
          <select value={filters.categorie} onChange={e => setFilter('categorie', e.target.value)} className="input-field w-auto">
            <option value="">Toutes catégories</option>
            {categorieOptions.map(c => <option key={c.val} value={c.val}>{c.label}</option>)}
          </select>
          <select value={filters.forme} onChange={e => setFilter('forme', e.target.value)} className="input-field w-auto">
            <option value="">Toutes formes</option>
            {formeOptions.map(f => <option key={f.val} value={f.val}>{f.label}</option>)}
          </select>
          <select value={filters.couleur} onChange={e => setFilter('couleur', e.target.value)} className="input-field w-auto">
            <option value="">Toutes couleurs</option>
            {couleurOptions.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
          <div className="flex gap-2 items-center">
            <input value={filters.minPrix} onChange={e => setFilter('minPrix', e.target.value)} className="input-field w-24" placeholder="Min" type="number" />
            <span className="text-gray-400">—</span>
            <input value={filters.maxPrix} onChange={e => setFilter('maxPrix', e.target.value)} className="input-field w-24" placeholder="Max" type="number" />
          </div>
          {Object.entries(filters).some(([k, v]) => k !== 'page' && v) && (
            <button
              onClick={() => setFilters({ search: '', categorie: '', forme: '', couleur: '', minPrix: '', maxPrix: '', page: '1' })}
              className="btn-secondary flex items-center gap-2 text-sm"
            >
              <Filter className="w-4 h-4" /> Réinitialiser
            </button>
          )}
        </div>
      </div>

      {isLoading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {[...Array(8)].map((_, i) => <div key={i} className="rounded-2xl bg-gray-200 animate-pulse h-72" />)}
        </div>
      ) : montures.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <Filter className="w-12 h-12 mx-auto mb-3 opacity-40" />
          <p className="font-medium">Aucune monture trouvée</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {montures.map(m => <MontureCard key={m.id} monture={m} />)}
        </div>
      )}

      {totalPages > 1 && (
        <div className="flex justify-center gap-2 mt-8 flex-wrap">
          {[...Array(totalPages)].map((_, i) => (
            <button
              key={i}
              onClick={() => setFilters(f => ({ ...f, page: String(i + 1) }))}
              className={`w-9 h-9 rounded-xl text-sm font-medium transition-colors ${filters.page === String(i + 1) ? 'bg-primary-600 text-white' : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'}`}
            >
              {i + 1}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

function MontureCard({ monture }: { monture: Monture }) {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const m = monture as any;
  const imgSrc = m.image ? mediaUrl(m.image) : m.image_principale ? mediaUrl(m.image_principale) : null;

  return (
    <div className="bg-white rounded-2xl border border-gray-100 shadow-sm hover:shadow-md transition-all overflow-hidden group">
      <div className="relative bg-gray-100 h-48 overflow-hidden">
        {imgSrc ? (
          <img src={imgSrc} alt={monture.nom} loading="lazy" className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
        ) : (
          <div className="w-full h-full flex items-center justify-center text-gray-300">
            <svg className="w-16 h-16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
            </svg>
          </div>
        )}
        {monture.stock <= 3 && monture.stock > 0 && (
          <span className="absolute top-2 right-2 badge bg-orange-100 text-orange-700">Plus que {monture.stock}</span>
        )}
        {monture.stock === 0 && (
          <span className="absolute top-2 right-2 badge bg-red-100 text-red-700">Rupture</span>
        )}
      </div>
      <div className="p-4">
        <div className="text-xs text-gray-400 font-medium mb-1">{monture.marque}</div>
        <h3 className="font-semibold text-gray-900 mb-1 truncate">{monture.nom}</h3>
        <div className="flex items-center gap-2 text-xs text-gray-500 mb-3">
          <span className="badge bg-gray-100 text-gray-600">{monture.forme}</span>
          <span className="badge bg-gray-100 text-gray-600">{monture.couleur}</span>
        </div>
        <div className="flex items-center justify-between">
          <span className="font-bold text-sm text-gray-900">{formatCFA(monture.prix)}</span>
          <div className="flex gap-2">
            <Link
              to={`/essai-virtuel/${monture.id}`}
              className="p-2 bg-primary-50 text-primary-600 rounded-xl hover:bg-primary-100 transition-colors"
              title="Essai virtuel"
            >
              <Camera className="w-4 h-4" />
            </Link>
            <Link
              to={`/montures/${monture.id}`}
              className="p-2 bg-gray-100 text-gray-600 rounded-xl hover:bg-gray-200 transition-colors"
              title="Voir détails"
            >
              <ShoppingCart className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
