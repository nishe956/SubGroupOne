import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Building2, MapPin, Phone, Mail, Trash2, CheckCircle, XCircle, Clock, Check, X, User as UserIcon } from 'lucide-react';
import api, { mediaUrl } from '@/lib/api';
import toast from 'react-hot-toast';

export default function AdminOpticiens() {
  const qc = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['admin-opticiens'],
    queryFn: () => api.get('/boutiques/').then(r => r.data),
  });

  const { data: usersData } = useQuery({
    queryKey: ['opticiens-users'],
    queryFn: () => api.get('/users/opticiens/').then(r => r.data),
  });

  const { data: enAttenteData } = useQuery({
    queryKey: ['opticiens-en-attente'],
    queryFn: () => api.get('/users/opticiens/en-attente/').then(r => r.data),
  });

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const boutiques: any[] = Array.isArray(data) ? data : (data?.results || []);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const opticienUsers: any[] = Array.isArray(usersData) ? usersData : (usersData?.results || []);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const enAttente: any[] = Array.isArray(enAttenteData) ? enAttenteData : (enAttenteData?.results || []);

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
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-100">Gestion des opticiens</h1>
        <span className="text-sm text-gray-400">{boutiques.length} opticien{boutiques.length !== 1 ? 's' : ''}</span>
      </div>

      {/* Demandes en attente de validation */}
      {enAttente.length > 0 && (
        <div className="mb-8">
          <div className="flex items-center gap-2 mb-3">
            <Clock className="w-5 h-5 text-amber-400" />
            <h2 className="font-semibold text-gray-100">Demandes en attente</h2>
            <span className="badge bg-amber-900 text-amber-300 text-xs">{enAttente.length}</span>
          </div>
          <div className="grid gap-3">
            {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
            {enAttente.map((u: any) => (
              <div key={u.id} className="bg-gray-800 border border-amber-900/50 rounded-2xl p-4 flex items-center gap-4">
                <div className="w-11 h-11 bg-amber-900/40 rounded-xl flex items-center justify-center flex-shrink-0">
                  <UserIcon className="w-5 h-5 text-amber-300" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="font-semibold text-white">{u.first_name} {u.last_name} <span className="text-gray-500 font-normal">@{u.username}</span></div>
                  <div className="flex flex-wrap gap-x-4 gap-y-0.5 text-sm text-gray-400 mt-0.5">
                    {u.email && <span className="flex items-center gap-1"><Mail className="w-3.5 h-3.5" />{u.email}</span>}
                    {u.telephone && <span className="flex items-center gap-1"><Phone className="w-3.5 h-3.5" />{u.telephone}</span>}
                  </div>
                </div>
                <div className="flex items-center gap-2 flex-shrink-0">
                  <button
                    onClick={() => validerMutation.mutate({ id: u.id, action: 'approuver' })}
                    disabled={validerMutation.isPending}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-green-600 hover:bg-green-700 text-white text-sm font-medium transition-colors disabled:opacity-50"
                  >
                    <Check className="w-4 h-4" /> Accepter
                  </button>
                  <button
                    onClick={() => validerMutation.mutate({ id: u.id, action: 'rejeter' })}
                    disabled={validerMutation.isPending}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-gray-700 hover:bg-red-900/40 text-red-300 text-sm font-medium transition-colors disabled:opacity-50"
                  >
                    <X className="w-4 h-4" /> Refuser
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {isLoading ? (
        <div className="grid gap-4">{[...Array(3)].map((_, i) => <div key={i} className="h-28 bg-gray-700 animate-pulse rounded-2xl" />)}</div>
      ) : boutiques.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <Building2 className="w-12 h-12 mx-auto mb-3 opacity-40" />
          <p>Aucun opticien enregistré</p>
        </div>
      ) : (
        <div className="grid gap-4">
          {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
          {boutiques.map((b: any) => {
            const user = opticienUsers.find((u: any) => u.id === b.opticien);
            const logoSrc = b.logo ? mediaUrl(b.logo) : null;

            return (
              <div key={b.id} className="bg-gray-800 rounded-2xl p-5 flex items-start gap-4">
                {/* Logo */}
                <div className="w-14 h-14 bg-gray-700 rounded-xl flex items-center justify-center flex-shrink-0 overflow-hidden">
                  {logoSrc
                    ? <img src={logoSrc} alt={b.nom} loading="lazy" className="w-full h-full object-cover" />
                    : <Building2 className="w-7 h-7 text-gray-400" />
                  }
                </div>

                {/* Infos */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1 flex-wrap">
                    <span className="font-semibold text-white text-lg">{b.nom}</span>
                    <span className={`badge text-xs ${b.actif ? 'bg-green-900 text-green-300' : 'bg-gray-700 text-gray-400'}`}>
                      {b.actif ? <><CheckCircle className="w-3 h-3 inline mr-1" />Actif</> : <><XCircle className="w-3 h-3 inline mr-1" />Inactif</>}
                    </span>
                  </div>

                  {/* Propriétaire */}
                  {user && (
                    <div className="text-sm text-primary-400 mb-2">
                      👤 {user.first_name} {user.last_name}
                      <span className="text-gray-500 ml-2">@{user.username}</span>
                    </div>
                  )}

                  <div className="flex flex-wrap gap-x-4 gap-y-1 text-sm text-gray-400">
                    {b.adresse && (
                      <span className="flex items-center gap-1">
                        <MapPin className="w-3.5 h-3.5" /> {b.adresse}
                      </span>
                    )}
                    {b.telephone && (
                      <span className="flex items-center gap-1">
                        <Phone className="w-3.5 h-3.5" /> {b.telephone}
                      </span>
                    )}
                    {b.email && (
                      <span className="flex items-center gap-1">
                        <Mail className="w-3.5 h-3.5" /> {b.email}
                      </span>
                    )}
                  </div>

                  {b.slogan && <p className="text-xs text-gray-500 italic mt-1">"{b.slogan}"</p>}
                </div>

                {/* Actions */}
                <div className="flex flex-col items-end gap-2 flex-shrink-0">
                  <div className="text-xs text-gray-500">
                    {new Date(b.date_creation).toLocaleDateString('fr-FR')}
                  </div>
                  {b.opticien && (
                    <button
                      onClick={() => handleDelete(b.opticien, b.nom)}
                      disabled={deleteMutation.isPending}
                      className="p-1.5 rounded-lg text-red-400 hover:bg-red-900/30 transition-colors"
                      title="Supprimer cet opticien"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
