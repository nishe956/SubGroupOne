import { useState, type ReactElement } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { FileText, Check, X, ChevronRight, ChevronDown, MapPin, ExternalLink, Clock, Package, Truck, Star } from 'lucide-react';
import api, { formatCFA } from '@/lib/api';
import toast from 'react-hot-toast';

const statutLabels: Record<string, string> = {
  en_attente: 'En attente', validee: 'Validée', en_preparation: 'En préparation',
  expediee: 'Expédiée', livree: 'Livrée', rejetee: 'Rejetée', annulee: 'Annulée',
};

const statutColors: Record<string, string> = {
  en_attente: 'bg-yellow-100 text-yellow-700 border-yellow-200',
  validee: 'bg-blue-100 text-blue-700 border-blue-200',
  en_preparation: 'bg-purple-100 text-purple-700 border-purple-200',
  expediee: 'bg-indigo-100 text-indigo-700 border-indigo-200',
  livree: 'bg-green-100 text-green-700 border-green-200',
  rejetee: 'bg-red-100 text-red-700 border-red-200',
  annulee: 'bg-gray-100 text-gray-500 border-gray-200',
};

const statutRowLeft: Record<string, string> = {
  en_attente: 'border-l-4 border-l-yellow-400',
  validee: 'border-l-4 border-l-blue-400',
  en_preparation: 'border-l-4 border-l-purple-400',
  expediee: 'border-l-4 border-l-indigo-400',
  livree: 'border-l-4 border-l-green-400',
  rejetee: 'border-l-4 border-l-red-300',
  annulee: 'border-l-4 border-l-gray-300',
};

const statutIcons: Record<string, ReactElement> = {
  en_attente: <Clock className="w-3.5 h-3.5" />,
  validee: <Check className="w-3.5 h-3.5" />,
  en_preparation: <Package className="w-3.5 h-3.5" />,
  expediee: <Truck className="w-3.5 h-3.5" />,
  livree: <Star className="w-3.5 h-3.5" />,
  rejetee: <X className="w-3.5 h-3.5" />,
};

// Flux logique : quel est le prochain statut naturel
const nextStatut: Record<string, string> = {
  validee: 'en_preparation',
  en_preparation: 'livree',
  expediee: 'livree',
};

const nextLabel: Record<string, string> = {
  validee: 'Marquer en préparation',
  en_preparation: 'Marquer livrée',
  expediee: 'Marquer livrée',
};

const FILTRES = ['', 'en_attente', 'validee', 'en_preparation', 'livree', 'rejetee'];

export default function OpticienCommandes() {
  const qc = useQueryClient();
  const [filterStatut, setFilterStatut] = useState('');
  const [expandedId, setExpandedId] = useState<number | null>(null);
  const [rejetModal, setRejetModal] = useState<{ id: number; clientNom: string } | null>(null);
  const [noteRejet, setNoteRejet] = useState('');
  const [pendingId, setPendingId] = useState<number | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ['opticien-commandes'],
    queryFn: () => api.get('/commandes/').then(r => r.data),
  });

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const commandes: any[] = Array.isArray(data) ? data : (data?.results || []);

  const gererMutation = useMutation({
    mutationFn: ({ id, statut, notes }: { id: number; statut: string; notes?: string }) =>
      api.post(`/commandes/${id}/gerer/`, { statut, notes }),
    onSuccess: (_, vars) => {
      toast.success(`Commande ${statutLabels[vars.statut].toLowerCase()}`);
      qc.invalidateQueries({ queryKey: ['opticien-commandes'] });
      setPendingId(null);
      setRejetModal(null);
      setNoteRejet('');
    },
    onError: () => { toast.error('Erreur lors de la mise à jour'); setPendingId(null); },
  });

  const agir = (id: number, statut: string, notes?: string) => {
    setPendingId(id);
    gererMutation.mutate({ id, statut, notes });
  };

  const confirmerRejet = () => {
    if (!rejetModal) return;
    agir(rejetModal.id, 'rejetee', noteRejet || 'Commande refusée');
  };

  // Stats par statut
  const stats = commandes.reduce<Record<string, number>>((acc, c) => {
    acc[c.statut] = (acc[c.statut] || 0) + 1;
    return acc;
  }, {});

  // Trier : en_attente en premier, puis par date décroissante
  const ORDRE_STATUT: Record<string, number> = { en_attente: 0, validee: 1, en_preparation: 2, expediee: 3, livree: 4, rejetee: 5, annulee: 6 };
  const filtered = commandes
    .filter(c => !filterStatut || c.statut === filterStatut)
    .sort((a, b) => {
      const diff = (ORDRE_STATUT[a.statut] ?? 9) - (ORDRE_STATUT[b.statut] ?? 9);
      if (diff !== 0) return diff;
      return new Date(b.date_commande).getTime() - new Date(a.date_commande).getTime();
    });

  return (
    <div>
      {/* En-tête */}
      <div className="flex items-center justify-between mb-4 flex-wrap gap-3">
        <h1 className="text-2xl font-bold text-gray-900">Commandes reçues</h1>
        <span className="text-sm text-gray-400">{commandes.length} au total</span>
      </div>

      {/* Barre de stats rapides */}
      {!isLoading && commandes.length > 0 && (
        <div className="flex gap-2 mb-4 overflow-x-auto pb-1">
          {FILTRES.map(s => {
            const count = s ? (stats[s] || 0) : commandes.length;
            const label = s ? statutLabels[s] : 'Toutes';
            const active = filterStatut === s;
            return (
              <button
                key={s}
                onClick={() => setFilterStatut(s)}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium border transition-all whitespace-nowrap flex-shrink-0 ${
                  active
                    ? (s ? statutColors[s] : 'bg-gray-900 text-white border-gray-900')
                    : 'bg-white text-gray-500 border-gray-200 hover:border-gray-300'
                }`}
              >
                {s && statutIcons[s]}
                {label}
                <span className={`text-xs font-bold ml-0.5 ${active ? '' : 'text-gray-400'}`}>{count}</span>
              </button>
            );
          })}
        </div>
      )}

      {/* Liste */}
      {isLoading ? (
        <div className="space-y-2">
          {[...Array(5)].map((_, i) => <div key={i} className="h-16 bg-gray-100 animate-pulse rounded-2xl" />)}
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <FileText className="w-12 h-12 mx-auto mb-3 opacity-40" />
          <p>Aucune commande{filterStatut ? ` « ${statutLabels[filterStatut]} »` : ''}</p>
        </div>
      ) : (
        <div className="space-y-2">
          {filtered.map(c => {
            const monture = c.monture_detail;
            const statut: string = c.statut || 'en_attente';
            const clientNom: string = c.client_nom || 'Client';
            const isExpanded = expandedId === c.id;
            const isBusy = pendingId === c.id && gererMutation.isPending;
            const terminal = ['livree', 'rejetee', 'annulee'].includes(statut);

            return (
              <div key={c.id} className={`bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden ${statutRowLeft[statut] || ''}`}>

                {/* Ligne principale */}
                <div className="flex items-center gap-3 px-4 py-3">
                  {/* Info commande */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-semibold text-gray-900 text-sm">{clientNom}</span>
                      <span className={`inline-flex items-center gap-1 text-xs font-medium px-2 py-0.5 rounded-full border ${statutColors[statut] || 'bg-gray-100 text-gray-500'}`}>
                        {statutIcons[statut]} {statutLabels[statut]}
                      </span>
                    </div>
                    <div className="text-xs text-gray-500 truncate mt-0.5">
                      {monture?.nom}{monture?.marque ? ` · ${monture.marque}` : ''} · <span className="font-medium text-gray-700">{formatCFA(c.prix_total)}</span>
                    </div>
                    <div className="text-xs text-gray-400 mt-0.5">
                      {c.date_commande ? new Date(c.date_commande).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' }) : ''}
                    </div>
                  </div>

                  {/* Actions rapides */}
                  <div className="flex items-center gap-2 flex-shrink-0">
                    {statut === 'en_attente' && (
                      <>
                        <button
                          onClick={() => { setRejetModal({ id: c.id, clientNom }); setNoteRejet(''); }}
                          disabled={isBusy}
                          title="Refuser"
                          className="w-8 h-8 rounded-full flex items-center justify-center bg-red-50 text-red-500 hover:bg-red-100 border border-red-200 transition-all disabled:opacity-50"
                        >
                          <X className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => agir(c.id, 'validee')}
                          disabled={isBusy}
                          title="Valider"
                          className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-green-500 text-white hover:bg-green-600 text-xs font-semibold transition-all disabled:opacity-50 shadow-sm"
                        >
                          {isBusy ? <span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" /> : <Check className="w-3.5 h-3.5" />}
                          Valider
                        </button>
                      </>
                    )}

                    {!terminal && statut !== 'en_attente' && nextStatut[statut] && (
                      <button
                        onClick={() => agir(c.id, nextStatut[statut])}
                        disabled={isBusy}
                        title={nextLabel[statut]}
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-primary-50 text-primary-700 hover:bg-primary-100 border border-primary-200 text-xs font-semibold transition-all disabled:opacity-50"
                      >
                        {isBusy ? <span className="w-3.5 h-3.5 border-2 border-primary-400 border-t-transparent rounded-full animate-spin" /> : <ChevronRight className="w-3.5 h-3.5" />}
                        {nextLabel[statut]}
                      </button>
                    )}

                    {/* Bouton détails */}
                    <button
                      onClick={() => setExpandedId(isExpanded ? null : c.id)}
                      className="w-7 h-7 rounded-full flex items-center justify-center text-gray-400 hover:bg-gray-100 transition-all"
                    >
                      <ChevronDown className={`w-4 h-4 transition-transform ${isExpanded ? 'rotate-180' : ''}`} />
                    </button>
                  </div>
                </div>

                {/* Panneau détails (expandable) */}
                {isExpanded && (
                  <div className="border-t border-gray-100 px-4 py-3 bg-gray-50 space-y-3 text-sm">

                    {/* Infos monture */}
                    {monture && (
                      <div className="flex items-center gap-3">
                        {monture.image_principale && (
                          <img src={monture.image_principale} alt={monture.nom} className="w-12 h-12 rounded-xl object-cover border border-gray-200" />
                        )}
                        <div>
                          <div className="font-medium text-gray-800">{monture.nom}</div>
                          <div className="text-xs text-gray-500">{monture.marque} · {monture.forme} · {monture.couleur}</div>
                        </div>
                      </div>
                    )}

                    <div className="grid grid-cols-2 gap-2 text-xs">
                      {c.methode_paiement && (
                        <div className="bg-white rounded-xl px-3 py-2 border border-gray-100">
                          <div className="text-gray-400 mb-0.5">Paiement</div>
                          <div className="font-medium text-gray-700 capitalize">{c.methode_paiement.replace('_', ' ')}</div>
                          {c.telephone_paiement && <div className="text-gray-500">{c.telephone_paiement}</div>}
                        </div>
                      )}
                      {c.numero_assurance && (
                        <div className="bg-white rounded-xl px-3 py-2 border border-gray-100">
                          <div className="text-gray-400 mb-0.5">Assurance</div>
                          <div className="font-medium text-gray-700">{c.numero_assurance}</div>
                        </div>
                      )}
                    </div>

                    {/* Adresse / GPS */}
                    {(c.adresse_livraison || c.latitude) && (
                      <div className="bg-white rounded-xl px-3 py-2 border border-gray-100">
                        <div className="text-xs text-gray-400 mb-1 flex items-center gap-1">
                          <MapPin className="w-3 h-3" /> Livraison
                        </div>
                        {c.latitude && c.longitude ? (
                          <div className="space-y-1.5">
                            <p className="text-xs text-gray-600 leading-relaxed">{c.adresse_livraison}</p>
                            <a
                              href={`https://www.google.com/maps?q=${c.latitude},${c.longitude}`}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="inline-flex items-center gap-1 text-xs text-primary-600 hover:underline font-medium"
                            >
                              <ExternalLink className="w-3 h-3" /> Ouvrir sur Google Maps
                            </a>
                          </div>
                        ) : (
                          <p className="text-xs text-gray-600">{c.adresse_livraison}</p>
                        )}
                      </div>
                    )}

                    {c.notes && (
                      <div className="bg-white rounded-xl px-3 py-2 border border-gray-100">
                        <div className="text-xs text-gray-400 mb-0.5">Notes</div>
                        <p className="text-xs text-gray-600">{c.notes}</p>
                      </div>
                    )}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* Modal de refus */}
      {rejetModal && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-4 bg-black/40 backdrop-blur-sm" onClick={() => setRejetModal(null)}>
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-sm p-5" onClick={e => e.stopPropagation()}>
            <div className="flex items-center gap-3 mb-4">
              <div className="w-9 h-9 rounded-full bg-red-100 flex items-center justify-center">
                <X className="w-5 h-5 text-red-500" />
              </div>
              <div>
                <div className="font-semibold text-gray-900 text-sm">Refuser la commande</div>
                <div className="text-xs text-gray-400">{rejetModal.clientNom}</div>
              </div>
            </div>
            <label className="block text-xs font-medium text-gray-600 mb-1.5">Motif du refus (optionnel)</label>
            <textarea
              value={noteRejet}
              onChange={e => setNoteRejet(e.target.value)}
              className="input-field text-sm w-full resize-none"
              rows={3}
              placeholder="Ex: Article indisponible, commande en double..."
              autoFocus
            />
            <div className="flex gap-2 mt-4">
              <button onClick={() => setRejetModal(null)} className="btn-secondary flex-1 text-sm">Annuler</button>
              <button
                onClick={confirmerRejet}
                disabled={gererMutation.isPending}
                className="flex-1 py-2 px-4 rounded-xl bg-red-500 hover:bg-red-600 text-white font-semibold text-sm transition-all disabled:opacity-50"
              >
                {gererMutation.isPending ? 'Refus...' : 'Confirmer le refus'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
