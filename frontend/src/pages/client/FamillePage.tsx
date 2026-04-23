import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Users, Plus, UserPlus, LogIn, Tag } from 'lucide-react';
import api from '@/lib/api';
import { GroupeFamille } from '@/types';
import toast from 'react-hot-toast';

export default function FamillePage() {
  const qc = useQueryClient();
  const [showCreate, setShowCreate] = useState(false);
  const [showJoin, setShowJoin] = useState(false);
  const [showInvite, setShowInvite] = useState(false);
  const [nomGroupe, setNomGroupe] = useState('');
  const [codeJoin, setCodeJoin] = useState('');
  const [emailInvite, setEmailInvite] = useState('');

  const { data: groupe, isLoading } = useQuery<GroupeFamille | null>({
    queryKey: ['famille'],
    queryFn: () => api.get('/famille/').then(r => r.data).catch(() => null),
  });

  const { data: membresData } = useQuery({
    queryKey: ['famille-membres'],
    queryFn: () => api.get('/famille/membres/').then(r => r.data),
    enabled: !!groupe,
  });

  const membres: User[] = Array.isArray(membresData) ? membresData : [];

  const creerMutation = useMutation({
    mutationFn: () => api.post('/famille/creer/', { nom: nomGroupe }),
    onSuccess: () => { toast.success('Groupe créé !'); qc.invalidateQueries({ queryKey: ['famille'] }); setShowCreate(false); setNomGroupe(''); },
    onError: (err: unknown) => {
      const msg = (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail || 'Erreur lors de la création';
      toast.error(msg);
    },
  });

  const rejoindre = useMutation({
    mutationFn: () => api.post('/famille/rejoindre/', { code: codeJoin }),
    onSuccess: () => { toast.success('Vous avez rejoint le groupe !'); qc.invalidateQueries({ queryKey: ['famille'] }); setShowJoin(false); setCodeJoin(''); },
    onError: (err: unknown) => {
      const msg = (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail || 'Code invalide';
      toast.error(msg);
    },
  });

  const inviterMutation = useMutation({
    mutationFn: () => api.post('/famille/inviter/', { email: emailInvite }),
    onSuccess: () => { toast.success('Invitation envoyée !'); setShowInvite(false); setEmailInvite(''); },
    onError: (err: unknown) => {
      const msg = (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail || "Erreur lors de l'invitation";
      toast.error(msg);
    },
  });

  if (isLoading) return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary-600" /></div>;

  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold text-gray-900 mb-2">Groupe Famille</h1>
      <p className="text-gray-500 text-sm mb-6">Créez ou rejoignez un groupe famille pour bénéficier de rabais spéciaux.</p>

      {!groupe ? (
        <div className="space-y-4">
          <div className="card text-center py-10">
            <Users className="w-16 h-16 mx-auto mb-4 text-gray-300" />
            <h2 className="text-lg font-semibold text-gray-700 mb-2">Vous n'avez pas de groupe famille</h2>
            <p className="text-sm text-gray-500 mb-6">Créez un groupe ou rejoignez-en un avec un code d'invitation.</p>
            <div className="flex gap-3 justify-center flex-wrap">
              <button onClick={() => setShowCreate(true)} className="btn-primary flex items-center gap-2">
                <Plus className="w-4 h-4" /> Créer un groupe
              </button>
              <button onClick={() => setShowJoin(true)} className="btn-secondary flex items-center gap-2">
                <LogIn className="w-4 h-4" /> Rejoindre un groupe
              </button>
            </div>
          </div>

          {showCreate && (
            <div className="card border border-primary-100">
              <h3 className="font-semibold mb-3">Créer un groupe famille</h3>
              <input
                value={nomGroupe}
                onChange={e => setNomGroupe(e.target.value)}
                className="input-field mb-3"
                placeholder="Nom du groupe (ex: Famille Dupont)"
              />
              <div className="flex gap-2">
                <button onClick={() => creerMutation.mutate()} disabled={!nomGroupe || creerMutation.isPending} className="btn-primary">
                  {creerMutation.isPending ? 'Création...' : 'Créer'}
                </button>
                <button onClick={() => setShowCreate(false)} className="btn-secondary">Annuler</button>
              </div>
            </div>
          )}

          {showJoin && (
            <div className="card border border-primary-100">
              <h3 className="font-semibold mb-3">Rejoindre un groupe</h3>
              <input
                value={codeJoin}
                onChange={e => setCodeJoin(e.target.value)}
                className="input-field mb-3"
                placeholder="Code d'invitation"
              />
              <div className="flex gap-2">
                <button onClick={() => rejoindre.mutate()} disabled={!codeJoin || rejoindre.isPending} className="btn-primary">
                  {rejoindre.isPending ? 'Rejoindre...' : 'Rejoindre'}
                </button>
                <button onClick={() => setShowJoin(false)} className="btn-secondary">Annuler</button>
              </div>
            </div>
          )}
        </div>
      ) : (
        <div className="space-y-4">
          <div className="card">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 bg-primary-100 rounded-xl flex items-center justify-center">
                  <Users className="w-6 h-6 text-primary-600" />
                </div>
                <div>
                  <h2 className="font-bold text-gray-900">{groupe.nom}</h2>
                  <div className="text-xs text-gray-500">Code: <span className="font-mono font-bold text-primary-600">{groupe.code_invitation}</span></div>
                </div>
              </div>
              <button onClick={() => setShowInvite(!showInvite)} className="btn-secondary flex items-center gap-1 text-sm">
                <UserPlus className="w-4 h-4" /> Inviter
              </button>
            </div>

            {groupe.taux_rabais != null && (
              <div className="flex items-center gap-2 bg-yellow-50 text-yellow-700 rounded-xl px-4 py-3 mb-4">
                <Tag className="w-5 h-5" />
                <span className="font-semibold">Rabais famille : {groupe.taux_rabais}%</span>
              </div>
            )}

            {showInvite && (
              <div className="bg-gray-50 rounded-xl p-4 mb-4">
                <p className="text-sm font-medium text-gray-700 mb-2">Inviter par email</p>
                <div className="flex gap-2">
                  <input
                    value={emailInvite}
                    onChange={e => setEmailInvite(e.target.value)}
                    className="input-field text-sm"
                    placeholder="email@exemple.com"
                    type="email"
                  />
                  <button onClick={() => inviterMutation.mutate()} disabled={!emailInvite || inviterMutation.isPending} className="btn-primary text-sm whitespace-nowrap">
                    Envoyer
                  </button>
                </div>
              </div>
            )}

            {membres.length > 0 && (
              <div>
                <h3 className="font-medium text-gray-700 mb-2 text-sm">Membres ({membres.length})</h3>
                <div className="space-y-2">
                  {membres.map(m => (
                    <div key={m.id} className="flex items-center gap-3 p-2 bg-gray-50 rounded-xl">
                      <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center text-primary-700 font-bold text-sm">
                        {(m.first_name?.[0] || m.username?.[0] || '?').toUpperCase()}
                      </div>
                      <div>
                        <div className="text-sm font-medium text-gray-900">{m.first_name} {m.last_name}</div>
                        <div className="text-xs text-gray-400">{m.username}</div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
