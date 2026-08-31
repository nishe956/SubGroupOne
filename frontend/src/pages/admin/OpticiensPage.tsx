import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Building2, MapPin, Phone, Mail, Trash2, Clock, Check, X } from 'lucide-react';
import api, { mediaUrl, listeDepuis } from '@/lib/api';
import toast from 'react-hot-toast';
import { Carte, Badge, EnTetePage, Avatar } from '@/components/admin';

export default function AdminOpticiens() {
  const qc = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['admin-opticiens'],
    queryFn: () => api.get('/boutiques/').then(r => listeDepuis(r.data)),
  });

  const { data: usersData } = useQuery({
    queryKey: ['opticiens-users'],
    queryFn: () => api.get('/users/opticiens/').then(r => listeDepuis(r.data)),
  });

  const { data: enAttenteData } = useQuery({
    queryKey: ['opticiens-en-attente'],
    queryFn: () => api.get('/users/opticiens/en-attente/').then(r => listeDepuis(r.data)),
  });

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const boutiques: any[] = data ?? [];
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const opticienUsers: any[] = usersData ?? [];
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const enAttente: any[] = enAttenteData ?? [];

  const deleteMutation = useMutation({
    mutationFn: (id: number) => api.delete(`/users/${id}/`),
    onSuccess: () => { toast.success('Opticien supprimé'); qc.invalidateQueries({ queryKey: ['admin-opticiens'] }); },
    onError: () => toast.error('Erreur lors de la suppression'),
  });

  const validerMutation = useMutation({
    mutationFn: ({ id, action }: { id: number; action: 'approuver' | 'rejeter' }) =>
      api.post(`/users/opticiens/${id}/valider/`, { action }),
    onSuccess: (_res, { action }) => {
      toast.success(action === 'approuver' ? 'Opticien approuvé' : 'Demande rejetée');
      qc.invalidateQueries({ queryKey: ['opticiens-en-attente'] });
      qc.invalidateQueries({ queryKey: ['admin-opticiens'] });
      qc.invalidateQueries({ queryKey: ['opticiens-users'] });
    },
    onError: () => toast.error('Erreur lors du traitement de la demande'),
  });

  const handleDelete = (userId: number, nom: string) => {
    if (confirm(`Supprimer l'opticien "${nom}" ? Ses montures et boutique seront aussi supprimées.`)) {
      deleteMutation.mutate(userId);
    }
  };

  return (
    <div>
      <EnTetePage
        titre="Opticiens"
        sousTitre={`${boutiques.length} boutique${boutiques.length !== 1 ? 's' : ''} sur le réseau`}
      />

      {/* Demandes en attente : placées avant la liste, ce sont les seules
          lignes de cette page qui appellent une décision. */}
      {enAttente.length > 0 && (
        <Carte className="mb-6 border-amber-200 bg-amber-50">
          <div className="flex items-center gap-2 mb-4">
            <Clock className="w-4 h-4 text-amber-600" />
            <h2 className="font-semibold text-gray-900">Demandes en attente</h2>
            <Badge ton="attente">{enAttente.length}</Badge>
          </div>
          <ul className="space-y-3">
            {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
            {enAttente.map((u: any) => (
              <li key={u.id} className="bg-white rounded-xl border border-amber-100 p-4 flex flex-wrap items-center gap-4">
                <Avatar nom={`${u.first_name ?? ''} ${u.last_name ?? ''}`.trim() || u.username} taille="lg" />
                <div className="flex-1 min-w-[180px]">
                  <div className="font-semibold text-gray-900">
                    {u.first_name} {u.last_name}
                    <span className="text-gray-400 font-normal ml-2">@{u.username}</span>
                  </div>
                  <div className="flex flex-wrap gap-x-4 gap-y-0.5 text-sm text-gray-500 mt-0.5">
                    {u.email && <span className="flex items-center gap-1"><Mail className="w-3.5 h-3.5" />{u.email}</span>}
                    {u.telephone && <span className="flex items-center gap-1"><Phone className="w-3.5 h-3.5" />{u.telephone}</span>}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => validerMutation.mutate({ id: u.id, action: 'approuver' })}
                    disabled={validerMutation.isPending}
                    className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-sm font-medium transition-colors disabled:opacity-50"
                  >
                    <Check className="w-4 h-4" /> Accepter
                  </button>
                  <button
                    onClick={() => validerMutation.mutate({ id: u.id, action: 'rejeter' })}
                    disabled={validerMutation.isPending}
                    className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl border border-gray-200 hover:bg-red-50 hover:border-red-200 text-gray-600 hover:text-red-600 text-sm font-medium transition-colors disabled:opacity-50"
                  >
                    <X className="w-4 h-4" /> Refuser
                  </button>
                </div>
              </li>
            ))}
          </ul>
        </Carte>
      )}

      {isLoading ? (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {[...Array(3)].map((_, i) => <div key={i} className="h-44 bg-white border border-gray-100 rounded-2xl animate-pulse" />)}
        </div>
      ) : boutiques.length === 0 ? (
        <Carte className="text-center py-20">
          <Building2 className="w-10 h-10 mx-auto mb-3 text-gray-300" strokeWidth={1.5} />
          <div className="font-medium text-gray-700">Aucun opticien enregistré</div>
          <p className="text-sm text-gray-400 mt-1">Les boutiques validées apparaîtront ici.</p>
        </Carte>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
          {boutiques.map((b: any) => {
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            const proprietaire = opticienUsers.find((u: any) => u.id === b.opticien);
            const logoSrc = b.logo ? mediaUrl(b.logo) : null;

            return (
              <Carte key={b.id} className="flex flex-col">
                <div className="flex items-start gap-3 mb-4">
                  <div className="w-12 h-12 rounded-xl bg-gray-50 border border-gray-100 flex items-center justify-center flex-shrink-0 overflow-hidden">
                    {logoSrc
                      ? <img src={logoSrc} alt={b.nom} loading="lazy" className="w-full h-full object-cover" />
                      : <Building2 className="w-6 h-6 text-gray-400" strokeWidth={1.5} />}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="font-semibold text-gray-900 truncate">{b.nom}</div>
                    {proprietaire && (
                      <div className="text-xs text-gray-400 truncate">
                        {proprietaire.first_name} {proprietaire.last_name} · @{proprietaire.username}
                      </div>
                    )}
                  </div>
                  <Badge ton={b.actif ? 'succes' : 'neutre'}>{b.actif ? 'Actif' : 'Inactif'}</Badge>
                </div>

                <ul className="space-y-1.5 text-sm text-gray-500 flex-1">
                  {b.adresse && <li className="flex items-start gap-2"><MapPin className="w-3.5 h-3.5 mt-0.5 flex-shrink-0" />{b.adresse}</li>}
                  {b.telephone && <li className="flex items-center gap-2"><Phone className="w-3.5 h-3.5 flex-shrink-0" />{b.telephone}</li>}
                  {b.email && <li className="flex items-center gap-2 min-w-0"><Mail className="w-3.5 h-3.5 flex-shrink-0" /><span className="truncate">{b.email}</span></li>}
                </ul>

                {b.slogan && <p className="text-xs text-gray-400 italic mt-3">« {b.slogan} »</p>}

                <div className="flex items-center justify-between mt-4 pt-3 border-t border-gray-100">
                  <span className="text-xs text-gray-400">
                    Inscrite le {new Date(b.date_creation).toLocaleDateString('fr-FR')}
                  </span>
                  {b.opticien && (
                    <button
                      onClick={() => handleDelete(b.opticien, b.nom)}
                      disabled={deleteMutation.isPending}
                      title="Supprimer cet opticien"
                      aria-label={`Supprimer l'opticien ${b.nom}`}
                      className="p-2 rounded-lg text-red-500 hover:bg-red-50 transition-colors"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  )}
                </div>
              </Carte>
            );
          })}
        </div>
      )}
    </div>
  );
}
