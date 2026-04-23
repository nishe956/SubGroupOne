import { useState, useRef } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Trash2, X, AlertTriangle, Package } from 'lucide-react';
import api, { mediaUrl, formatCFA } from '@/lib/api';
import { Monture } from '@/types';
import toast from 'react-hot-toast';

const defaultForm = {
  nom: '', marque: '', categorie: 'adulte', couleur: 'Noir',
  forme: 'rectangulaire', prix: '', stock: '', description: '',
};

export default function OpticienMontures() {
  const qc = useQueryClient();
  const fileRef = useRef<HTMLInputElement>(null);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState(defaultForm);
  const [adjustId, setAdjustId] = useState<number | null>(null);
  const [adjustQty, setAdjustQty] = useState('');
  const [adjustRaison, setAdjustRaison] = useState('');

  const { data, isLoading } = useQuery({
    queryKey: ['opticien-montures'],
    queryFn: () => api.get('/montures/?mes_montures=true').then(r => r.data),
  });

  const { data: alertesData } = useQuery({
    queryKey: ['stock-alertes'],
    queryFn: () => api.get('/stock/alertes/').then(r => r.data),
  });

  const montures: Monture[] = Array.isArray(data) ? data : (data?.results || []);
  const alertes = Array.isArray(alertesData) ? alertesData : (alertesData?.results || alertesData?.alertes || []);

  const createMutation = useMutation({
    mutationFn: () => {
      const fd = new FormData();
      Object.entries(form).forEach(([k, v]) => fd.append(k, v));
      if (fileRef.current?.files?.[0]) {
        fd.append('image', fileRef.current.files[0]);
      }
      return api.post('/montures/', fd, { headers: { 'Content-Type': 'multipart/form-data' } });
    },
    onSuccess: () => {
      toast.success('Monture créée');
      qc.invalidateQueries({ queryKey: ['opticien-montures'] });
      setShowForm(false);
      setForm(defaultForm);
    },
    onError: (err: unknown) => {
      const msg = (err as { response?: { data?: Record<string, string[]> } })?.response?.data;
      toast.error(msg ? Object.values(msg).flat().join(' ') : 'Erreur lors de la création');
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => api.delete(`/montures/${id}/`),
    onSuccess: () => { toast.success('Monture supprimée'); qc.invalidateQueries({ queryKey: ['opticien-montures'] }); },
    onError: () => toast.error('Erreur lors de la suppression'),
  });

  const adjustMutation = useMutation({
    mutationFn: () => api.post('/stock/ajuster/', {
      monture_id: adjustId,
      quantite: Number(adjustQty),
      raison: adjustRaison,
    }),
    onSuccess: () => {
      toast.success('Stock ajusté');
      qc.invalidateQueries({ queryKey: ['opticien-montures'] });
      qc.invalidateQueries({ queryKey: ['stock-alertes'] });
      setAdjustId(null);
      setAdjustQty('');
      setAdjustRaison('');
    },
    onError: () => toast.error("Erreur lors de l'ajustement"),
  });

  const categorieOptions = [
    { val: 'adulte', label: 'Adulte' },
    { val: 'enfant', label: 'Enfant' },
    { val: 'sport', label: 'Sport' },
    { val: 'luxe', label: 'Luxe' },
  ];
  const formeOptions = [
    { val: 'ronde', label: 'Ronde' },
    { val: 'carree', label: 'Carrée' },
    { val: 'rectangulaire', label: 'Rectangulaire' },
    { val: 'ovale', label: 'Ovale' },
  ];
  const couleurOptions = ['Noir', 'Marron', 'Or', 'Argent', 'Bleu', 'Rouge', 'Écaille', 'Gris', 'Transparent'];

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Mes montures</h1>
        <button onClick={() => setShowForm(!showForm)} className="btn-primary flex items-center gap-2">
          {showForm ? <X className="w-4 h-4" /> : <Plus className="w-4 h-4" />}
          {showForm ? 'Annuler' : 'Ajouter'}
        </button>
      </div>

      {alertes.length > 0 && (
        <div className="card mb-4 border border-orange-200 bg-orange-50">
          <div className="flex items-center gap-2 mb-2">
            <AlertTriangle className="w-4 h-4 text-orange-600" />
            <span className="font-medium text-orange-700 text-sm">{alertes.length} alerte{alertes.length > 1 ? 's' : ''} de stock bas</span>
          </div>
          <div className="space-y-1">
            {alertes.slice(0, 5).map((a: { id: number; monture?: Monture; monture_nom?: string; stock_actuel?: number }) => (
              <div key={a.id} className="text-xs text-orange-600">
                • {a.monture?.nom || a.monture_nom || `Monture #${a.id}`}: stock {a.monture?.stock ?? a.stock_actuel ?? '?'}
              </div>
            ))}
          </div>
        </div>
      )}

      {showForm && (
        <div className="card mb-6 border border-primary-100">
          <h2 className="font-semibold text-gray-900 mb-4">Nouvelle monture</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3 mb-3">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Nom</label>
              <input value={form.nom} onChange={e => setForm(f => ({ ...f, nom: e.target.value }))} className="input-field" placeholder="Classic Round" required />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Marque</label>
              <input value={form.marque} onChange={e => setForm(f => ({ ...f, marque: e.target.value }))} className="input-field" placeholder="RayBan" required />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Catégorie</label>
              <select value={form.categorie} onChange={e => setForm(f => ({ ...f, categorie: e.target.value }))} className="input-field">
                {categorieOptions.map(c => <option key={c.val} value={c.val}>{c.label}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Forme</label>
              <select value={form.forme} onChange={e => setForm(f => ({ ...f, forme: e.target.value }))} className="input-field">
                {formeOptions.map(f => <option key={f.val} value={f.val}>{f.label}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Couleur</label>
              <select value={form.couleur} onChange={e => setForm(f => ({ ...f, couleur: e.target.value }))} className="input-field">
                {couleurOptions.map(c => <option key={c}>{c}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Prix (F CFA)</label>
              <input type="number" value={form.prix} onChange={e => setForm(f => ({ ...f, prix: e.target.value }))} className="input-field" placeholder="25000" required />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Stock</label>
              <input type="number" value={form.stock} onChange={e => setForm(f => ({ ...f, stock: e.target.value }))} className="input-field" placeholder="10" required />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Images</label>
              <input ref={fileRef} type="file" multiple accept="image/*" className="input-field text-sm" />
            </div>
          </div>
          <div className="mb-3">
            <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
            <input value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} className="input-field" placeholder="Description..." />
          </div>
          <button
            onClick={() => createMutation.mutate()}
            disabled={!form.nom || !form.marque || !form.prix || !form.stock || createMutation.isPending}
            className="btn-primary"
          >
            {createMutation.isPending ? 'Création...' : 'Créer la monture'}
          </button>
        </div>
      )}

      {adjustId !== null && (
        <div className="card mb-4 border border-blue-200 bg-blue-50">
          <h3 className="font-medium text-blue-800 mb-3">Ajuster le stock</h3>
          <div className="flex gap-3 flex-wrap">
            <input
              type="number"
              value={adjustQty}
              onChange={e => setAdjustQty(e.target.value)}
              className="input-field w-28"
              placeholder="Quantité (+/-)"
            />
            <input
              value={adjustRaison}
              onChange={e => setAdjustRaison(e.target.value)}
              className="input-field flex-1 min-w-40"
              placeholder="Raison"
            />
            <button onClick={() => adjustMutation.mutate()} disabled={!adjustQty || adjustMutation.isPending} className="btn-primary">
              Confirmer
            </button>
            <button onClick={() => setAdjustId(null)} className="btn-secondary">Annuler</button>
          </div>
        </div>
      )}

      {isLoading ? (
        <div className="grid gap-3">{[...Array(4)].map((_, i) => <div key={i} className="h-20 bg-gray-200 animate-pulse rounded-2xl" />)}</div>
      ) : montures.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <Package className="w-12 h-12 mx-auto mb-3 opacity-40" />
          <p>Aucune monture. Ajoutez votre première monture !</p>
        </div>
      ) : (
        <div className="card p-0 overflow-hidden overflow-x-auto">
          <table className="w-full min-w-[600px]">
            <thead className="bg-gray-50 border-b border-gray-100">
              <tr>
                {['Monture', 'Forme / Couleur', 'Prix', 'Stock', 'Statut', 'Actions'].map(h => (
                  <th key={h} className="text-left text-xs font-medium text-gray-500 uppercase tracking-wider px-4 py-3">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {montures.map(m => {
                const imgSrc = m.image ? mediaUrl(m.image) : m.image_principale ? mediaUrl(m.image_principale) : null;
                return (
                  <tr key={m.id} className={`hover:bg-gray-50 ${m.stock <= 3 && m.stock > 0 ? 'bg-orange-50' : m.stock === 0 ? 'bg-red-50' : ''}`}>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 bg-gray-100 rounded-xl overflow-hidden flex-shrink-0">
                          {imgSrc ? <img src={imgSrc} alt="" loading="lazy" className="w-full h-full object-cover" /> : <div className="w-full h-full bg-gray-200" />}
                        </div>
                        <div>
                          <div className="font-medium text-sm text-gray-900">{m.nom}</div>
                          <div className="text-xs text-gray-400">{m.marque}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-600">{m.forme} / {m.couleur}</td>
                    <td className="px-4 py-3 font-semibold text-sm text-gray-900">{formatCFA(m.prix)}</td>
                    <td className="px-4 py-3 text-sm">
                      <span className={m.stock === 0 ? 'text-red-600 font-bold' : m.stock <= 3 ? 'text-orange-600 font-bold' : 'text-gray-600'}>
                        {m.stock}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`badge ${m.disponible ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                        {m.disponible ? 'Actif' : 'Inactif'}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex gap-2">
                        <button
                          onClick={() => { setAdjustId(m.id); setAdjustQty(''); setAdjustRaison(''); }}
                          className="text-blue-400 hover:text-blue-600 p-1 text-xs"
                          title="Ajuster stock"
                        >
                          Ajuster
                        </button>
                        <button
                          onClick={() => { if (window.confirm('Supprimer cette monture ?')) deleteMutation.mutate(m.id); }}
                          className="text-red-400 hover:text-red-600 p-1"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
