import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, X, Shield } from 'lucide-react';
import api from '@/lib/api';
import { CompagnieAssurance } from '@/types';
import toast from 'react-hot-toast';

export default function AdminAssurances() {
  const qc = useQueryClient();
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ nom: '', code: '', taux_prise_charge: '', plafond_annuel: '' });

  const { data, isLoading } = useQuery({
    queryKey: ['compagnies-assurance'],
    queryFn: () => api.get('/assurance/compagnies/').then(r => r.data),
  });

  const assurances: CompagnieAssurance[] = data?.results || data || [];

  const createMutation = useMutation({
    mutationFn: () => api.post('/assurance/compagnies/', {
      ...form,
      taux_prise_charge: Number(form.taux_prise_charge),
      plafond_annuel: form.plafond_annuel ? Number(form.plafond_annuel) : null,
    }),
    onSuccess: () => {
      toast.success('Assurance créée');
      qc.invalidateQueries({ queryKey: ['compagnies-assurance'] });
      setShowForm(false);
      setForm({ nom: '', code: '', taux_prise_charge: '', plafond_annuel: '' });
    },
    onError: () => toast.error('Erreur lors de la création'),
  });

  return (
    <div>
      <div className="flex items-center justify-between mb-6 flex-wrap gap-3">
        <h1 className="text-2xl font-bold text-gray-100">Gestion des assurances</h1>
        <button
          onClick={() => setShowForm(!showForm)}
          className="flex items-center gap-2 bg-primary-600 hover:bg-primary-700 text-white px-4 py-2.5 rounded-xl text-sm font-medium transition-colors"
        >
          {showForm ? <X className="w-4 h-4" /> : <Plus className="w-4 h-4" />}
          {showForm ? 'Annuler' : 'Ajouter'}
        </button>
      </div>

      {showForm && (
        <div className="bg-gray-800 rounded-2xl p-5 mb-5">
          <h2 className="font-semibold text-white mb-4">Nouvelle assurance</h2>
          <div className="grid grid-cols-2 gap-3 mb-3">
            <div>
              <label className="block text-sm text-gray-400 mb-1">Nom</label>
              <input
                value={form.nom}
                onChange={e => setForm(f => ({ ...f, nom: e.target.value }))}
                className="w-full bg-gray-700 text-white rounded-xl px-4 py-2.5 text-sm outline-none border border-gray-600 focus:border-primary-500"
                placeholder="MGEN"
              />
            </div>
            <div>
              <label className="block text-sm text-gray-400 mb-1">Code</label>
              <input
                value={form.code}
                onChange={e => setForm(f => ({ ...f, code: e.target.value.toUpperCase() }))}
                className="w-full bg-gray-700 text-white rounded-xl px-4 py-2.5 text-sm outline-none border border-gray-600 focus:border-primary-500"
                placeholder="MGEN"
              />
            </div>
            <div>
              <label className="block text-sm text-gray-400 mb-1">Taux remboursement (%)</label>
              <input
                type="number"
                value={form.taux_prise_charge}
                onChange={e => setForm(f => ({ ...f, taux_prise_charge: e.target.value }))}
                className="w-full bg-gray-700 text-white rounded-xl px-4 py-2.5 text-sm outline-none border border-gray-600 focus:border-primary-500"
                placeholder="70"
              />
            </div>
            <div>
              <label className="block text-sm text-gray-400 mb-1">Plafond (optionnel)</label>
              <input
                type="number"
                value={form.plafond_annuel}
                onChange={e => setForm(f => ({ ...f, plafond_annuel: e.target.value }))}
                className="w-full bg-gray-700 text-white rounded-xl px-4 py-2.5 text-sm outline-none border border-gray-600 focus:border-primary-500"
                placeholder="300000"
              />
            </div>
          </div>
          <button
            onClick={() => createMutation.mutate()}
            disabled={!form.nom || !form.code || !form.taux_prise_charge || createMutation.isPending}
            className="bg-primary-600 hover:bg-primary-700 text-white px-5 py-2.5 rounded-xl text-sm font-medium transition-colors disabled:opacity-50"
          >
            {createMutation.isPending ? 'Création...' : "Créer l'assurance"}
          </button>
        </div>
      )}

      {isLoading ? (
        <div className="grid gap-3">{[...Array(3)].map((_, i) => <div key={i} className="h-16 bg-gray-700 animate-pulse rounded-2xl" />)}</div>
      ) : (
        <div className="grid gap-3">
          {assurances.map(a => (
            <div key={a.id} className="bg-gray-800 rounded-2xl p-4 flex items-center gap-4">
              <div className="w-10 h-10 bg-green-900 rounded-xl flex items-center justify-center">
                <Shield className="w-5 h-5 text-green-400" />
              </div>
              <div className="flex-1">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="font-semibold text-white">{a.nom}</span>
                  <span className="badge bg-gray-700 text-gray-300 text-xs">{a.code}</span>
                  <span className={`badge ${a.active ? 'bg-green-900 text-green-300' : 'bg-gray-700 text-gray-400'}`}>
                    {a.active ? 'Active' : 'Inactive'}
                  </span>
                </div>
                <div className="text-sm text-gray-400">
                  Taux: {a.taux_prise_charge}%{a.plafond_annuel ? ` · Plafond: ${Number(a.plafond_annuel).toLocaleString('fr-FR')} F CFA` : ''}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
