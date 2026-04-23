import { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Gift, Users, Send, TrendingUp, Settings, Play, Check, Clock, MessageSquare, Zap } from 'lucide-react';
import api from '@/lib/api';
import { ClientAnniversaire, Segment } from '@/types';
import toast from 'react-hot-toast';

interface ConfigAuto {
  actif: boolean;
  message_template: string;
  heure_envoi: string;
}

export default function MarketingPage() {
  const qc = useQueryClient();
  const [showConfig, setShowConfig] = useState(false);
  const [messageEdit, setMessageEdit] = useState('');
  const [heureEdit, setHeureEdit] = useState('08:00');

  const { data: anniversairesData, isLoading: loadingAnniv } = useQuery({
    queryKey: ['anniversaires'],
    queryFn: () => api.get('/marketing/anniversaires/').then(r => r.data),
  });

  const { data: segmentsData, isLoading: loadingSegments } = useQuery({
    queryKey: ['segments'],
    queryFn: () => api.get('/marketing/segments/').then(r => r.data),
  });

  const { data: configData, isLoading: loadingConfig } = useQuery<ConfigAuto>({
    queryKey: ['config-auto-anniversaire'],
    queryFn: () => api.get('/marketing/auto-anniversaire/').then(r => r.data),
  });

  useEffect(() => {
    if (configData) {
      setMessageEdit(configData.message_template);
      setHeureEdit(configData.heure_envoi);
    }
  }, [configData]);

  const anniversaires: ClientAnniversaire[] = anniversairesData?.results || anniversairesData || [];
  const segments: Segment[] = segmentsData?.results || segmentsData || [];

  const souhaitsMutation = useMutation({
    mutationFn: (id: number) => api.post(`/marketing/souhaits/${id}/`),
    onSuccess: () => toast.success('Souhaits envoyés !'),
    onError: () => toast.error("Erreur lors de l'envoi"),
  });

  const toggleAutoMutation = useMutation({
    mutationFn: (actif: boolean) => api.patch('/marketing/auto-anniversaire/', { actif }),
    onSuccess: (_, actif) => {
      toast.success(actif ? 'Envoi automatique activé !' : 'Envoi automatique désactivé');
      qc.invalidateQueries({ queryKey: ['config-auto-anniversaire'] });
    },
    onError: () => toast.error('Erreur lors de la mise à jour'),
  });

  const saveConfigMutation = useMutation({
    mutationFn: () => api.patch('/marketing/auto-anniversaire/', {
      message_template: messageEdit,
      heure_envoi: heureEdit,
    }),
    onSuccess: () => {
      toast.success('Configuration sauvegardée');
      qc.invalidateQueries({ queryKey: ['config-auto-anniversaire'] });
      setShowConfig(false);
    },
    onError: () => toast.error('Erreur lors de la sauvegarde'),
  });

  const lancerMaintenantMutation = useMutation({
    mutationFn: () => api.post('/marketing/auto-anniversaire/lancer/'),
    onSuccess: (res) => {
      const nb = res.data.nb ?? 0;
      toast.success(nb > 0 ? `${nb} message(s) envoyé(s) !` : 'Aucun anniversaire aujourd\'hui');
      qc.invalidateQueries({ queryKey: ['anniversaires'] });
    },
    onError: () => toast.error('Erreur lors de l\'envoi'),
  });

  const isActif = configData?.actif ?? false;

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Marketing & CRM</h1>

      <div className="grid lg:grid-cols-2 gap-6">
        {/* Anniversaires */}
        <div className="card">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 bg-pink-100 rounded-xl flex items-center justify-center">
              <Gift className="w-5 h-5 text-pink-600" />
            </div>
            <div className="flex-1">
              <h2 className="font-semibold text-gray-900">Clients anniversaire</h2>
              <p className="text-xs text-gray-400">7 prochains jours</p>
            </div>
          </div>

          {/* Bloc envoi automatique */}
          {!loadingConfig && (
            <div className={`rounded-xl border-2 mb-4 transition-all ${isActif ? 'border-green-200 bg-green-50' : 'border-gray-200 bg-gray-50'}`}>
              <div className="flex items-center gap-3 px-4 py-3">
                <div className={`w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 ${isActif ? 'bg-green-100 text-green-600' : 'bg-gray-200 text-gray-400'}`}>
                  <Zap className="w-4 h-4" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-sm font-semibold text-gray-900">Envoi automatique</div>
                  <div className="text-xs text-gray-500">
                    {isActif
                      ? `Actif — envoi chaque jour à ${configData?.heure_envoi}`
                      : 'Désactivé — les messages ne sont pas envoyés'}
                  </div>
                </div>
                {/* Toggle */}
                <button
                  onClick={() => toggleAutoMutation.mutate(!isActif)}
                  disabled={toggleAutoMutation.isPending}
                  className={`relative w-11 h-6 rounded-full transition-colors flex-shrink-0 ${isActif ? 'bg-green-500' : 'bg-gray-300'}`}
                >
                  <span className={`absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform ${isActif ? 'translate-x-5' : 'translate-x-0'}`} />
                </button>
              </div>

              {/* Actions rapides */}
              <div className="flex gap-2 px-4 pb-3">
                <button
                  onClick={() => {
                    if (!showConfig) {
                      setMessageEdit(configData?.message_template ?? '');
                      setHeureEdit(configData?.heure_envoi ?? '08:00');
                    }
                    setShowConfig(v => !v);
                  }}
                  className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-lg border border-gray-200 bg-white text-gray-600 hover:bg-gray-50 transition-all"
                >
                  <Settings className="w-3 h-3" /> Configurer
                </button>
                <button
                  onClick={() => lancerMaintenantMutation.mutate()}
                  disabled={lancerMaintenantMutation.isPending}
                  className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-lg border border-blue-200 bg-blue-50 text-blue-600 hover:bg-blue-100 transition-all disabled:opacity-50"
                >
                  <Play className="w-3 h-3" />
                  {lancerMaintenantMutation.isPending ? 'Envoi...' : 'Lancer maintenant'}
                </button>
              </div>

              {/* Formulaire de configuration */}
              {showConfig && (
                <div className="border-t border-gray-200 px-4 py-4 bg-white rounded-b-xl space-y-3">
                  <div>
                    <label className="block text-xs font-medium text-gray-700 mb-1 flex items-center gap-1">
                      <Clock className="w-3 h-3" /> Heure d'envoi quotidien
                    </label>
                    <input
                      type="time"
                      value={heureEdit}
                      onChange={e => setHeureEdit(e.target.value)}
                      className="input-field text-sm w-32"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-700 mb-1 flex items-center gap-1">
                      <MessageSquare className="w-3 h-3" /> Message (utilisez {'{prenom}'} pour personnaliser)
                    </label>
                    <textarea
                      value={messageEdit}
                      onChange={e => setMessageEdit(e.target.value)}
                      rows={4}
                      className="input-field text-sm w-full resize-none"
                      placeholder="Joyeux anniversaire {prenom} ! ..."
                    />
                    <p className="text-xs text-gray-400 mt-1">
                      Aperçu : {messageEdit.replace('{prenom}', 'Mamadou')}
                    </p>
                  </div>
                  <div className="flex gap-2">
                    <button onClick={() => setShowConfig(false)} className="btn-secondary text-sm flex-1">Annuler</button>
                    <button
                      onClick={() => saveConfigMutation.mutate()}
                      disabled={saveConfigMutation.isPending}
                      className="btn-primary text-sm flex-1 flex items-center justify-center gap-1.5"
                    >
                      <Check className="w-3.5 h-3.5" />
                      {saveConfigMutation.isPending ? 'Sauvegarde...' : 'Sauvegarder'}
                    </button>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Liste des anniversaires à venir */}
          {loadingAnniv ? (
            <div className="space-y-2">{[...Array(3)].map((_, i) => <div key={i} className="h-12 bg-gray-100 animate-pulse rounded-xl" />)}</div>
          ) : anniversaires.length === 0 ? (
            <p className="text-sm text-gray-400 text-center py-4">Aucun anniversaire dans les 7 prochains jours</p>
          ) : (
            <div className="space-y-2">
              {anniversaires.map(c => (
                <div key={c.id} className="flex items-center justify-between p-3 rounded-xl bg-pink-50 border border-pink-100">
                  <div>
                    <div className="font-medium text-sm text-gray-900 flex items-center gap-2">
                      {c.nom}
                      <span className={`badge text-xs ${c.label === "Aujourd'hui" ? 'bg-pink-500 text-white' : 'bg-pink-100 text-pink-700'}`}>
                        {c.label} 🎂
                      </span>
                    </div>
                    {isActif && c.label === "Aujourd'hui" && (
                      <div className="text-xs text-green-600 flex items-center gap-1 mt-0.5">
                        <Zap className="w-2.5 h-2.5" /> Message auto prévu à {configData?.heure_envoi}
                      </div>
                    )}
                  </div>
                  <button
                    onClick={() => souhaitsMutation.mutate(c.id)}
                    disabled={souhaitsMutation.isPending}
                    className="flex items-center gap-1 text-xs bg-pink-500 hover:bg-pink-600 text-white px-3 py-1.5 rounded-xl transition-colors disabled:opacity-50"
                    title="Envoyer maintenant manuellement"
                  >
                    <Send className="w-3 h-3" /> Envoyer
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Segments */}
        <div className="card">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 bg-blue-100 rounded-xl flex items-center justify-center">
              <Users className="w-5 h-5 text-blue-600" />
            </div>
            <h2 className="font-semibold text-gray-900">Segments clients</h2>
          </div>

          {loadingSegments ? (
            <div className="space-y-2">{[...Array(3)].map((_, i) => <div key={i} className="h-12 bg-gray-100 animate-pulse rounded-xl" />)}</div>
          ) : segments.length === 0 ? (
            <p className="text-sm text-gray-400 text-center py-6">Aucun segment défini</p>
          ) : (
            <div className="space-y-2">
              {segments.map((s, i) => (
                <div key={i} className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                  <div>
                    <div className="font-medium text-sm text-gray-900">{s.nom}</div>
                    {s.description && <div className="text-xs text-gray-400">{s.description}</div>}
                  </div>
                  <span className="badge bg-blue-100 text-blue-700">{s.count} client{s.count > 1 ? 's' : ''}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Statistiques */}
      <div className="card mt-6">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 bg-green-100 rounded-xl flex items-center justify-center">
            <TrendingUp className="w-5 h-5 text-green-600" />
          </div>
          <h2 className="font-semibold text-gray-900">Statistiques</h2>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-gray-50 rounded-xl p-4 text-center">
            <div className="text-2xl font-bold text-gray-900">{anniversaires.length}</div>
            <div className="text-xs text-gray-500 mt-1">Anniversaires (7j)</div>
          </div>
          <div className={`rounded-xl p-4 text-center ${isActif ? 'bg-green-50' : 'bg-gray-50'}`}>
            <div className={`text-2xl font-bold ${isActif ? 'text-green-600' : 'text-gray-400'}`}>
              {isActif ? 'ON' : 'OFF'}
            </div>
            <div className="text-xs text-gray-500 mt-1">Envoi automatique</div>
          </div>
          <div className="bg-gray-50 rounded-xl p-4 text-center">
            <div className="text-2xl font-bold text-gray-900">{segments.reduce((s, seg) => s + (seg.count || 0), 0)}</div>
            <div className="text-xs text-gray-500 mt-1">Clients segmentés</div>
          </div>
          <div className="bg-gray-50 rounded-xl p-4 text-center">
            <div className="text-2xl font-bold text-gray-900">{segments.length}</div>
            <div className="text-xs text-gray-500 mt-1">Segments actifs</div>
          </div>
        </div>
      </div>
    </div>
  );
}
