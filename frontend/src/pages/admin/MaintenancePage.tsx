import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Settings, AlertTriangle, CheckCircle, Power } from 'lucide-react';
import api from '@/lib/api';
import { MaintenanceStatut } from '@/types';
import toast from 'react-hot-toast';

export default function MaintenancePage() {
  const qc = useQueryClient();
  const [message, setMessage] = useState('');

  const { data: statut, isLoading } = useQuery<MaintenanceStatut>({
    queryKey: ['maintenance-statut'],
    queryFn: () => api.get('/maintenance/statut/').then(r => r.data),
  });

  const { data: logsData } = useQuery({
    queryKey: ['maintenance-logs'],
    queryFn: () => api.get('/maintenance/logs/').then(r => r.data).catch(() => []),
  });

  const logs = logsData?.results || logsData || [];

  const activerMutation = useMutation({
    mutationFn: () => api.post('/maintenance/activer/', { message }),
    onSuccess: () => {
      toast.success('Mode maintenance activé');
      qc.invalidateQueries({ queryKey: ['maintenance-statut'] });
      qc.invalidateQueries({ queryKey: ['maintenance-logs'] });
    },
    onError: () => toast.error("Erreur lors de l'activation"),
  });

  const desactiverMutation = useMutation({
    mutationFn: () => api.post('/maintenance/desactiver/'),
    onSuccess: () => {
      toast.success('Mode maintenance désactivé');
      qc.invalidateQueries({ queryKey: ['maintenance-statut'] });
      qc.invalidateQueries({ queryKey: ['maintenance-logs'] });
    },
    onError: () => toast.error('Erreur lors de la désactivation'),
  });

  if (isLoading) return (
    <div className="flex justify-center py-20">
      <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary-600" />
    </div>
  );

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-100 mb-6">Maintenance</h1>

      <div className="bg-gray-800 rounded-2xl p-6 mb-6">
        <div className="flex items-center gap-4 mb-4">
          <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${statut?.actif ? 'bg-red-900' : 'bg-green-900'}`}>
            {statut?.actif ? <AlertTriangle className="w-6 h-6 text-red-400" /> : <CheckCircle className="w-6 h-6 text-green-400" />}
          </div>
          <div>
            <div className="font-bold text-white text-lg">
              {statut?.actif ? 'Mode maintenance ACTIF' : 'Système opérationnel'}
            </div>
            {statut?.message && <div className="text-sm text-gray-400">{statut.message}</div>}
            {statut?.debut && (
              <div className="text-xs text-gray-500">Depuis le {new Date(statut.debut).toLocaleString('fr-FR')}</div>
            )}
          </div>
        </div>

        {!statut?.actif ? (
          <div className="space-y-3">
            <div>
              <label className="block text-sm text-gray-400 mb-1">Message de maintenance (optionnel)</label>
              <input
                value={message}
                onChange={e => setMessage(e.target.value)}
                className="w-full bg-gray-700 text-white rounded-xl px-4 py-2.5 text-sm outline-none border border-gray-600 focus:border-primary-500"
                placeholder="Le site est en maintenance pour amélioration..."
              />
            </div>
            <button
              onClick={() => activerMutation.mutate()}
              disabled={activerMutation.isPending}
              className="flex items-center gap-2 bg-red-600 hover:bg-red-700 text-white px-5 py-2.5 rounded-xl text-sm font-medium transition-colors disabled:opacity-50"
            >
              <Power className="w-4 h-4" />
              {activerMutation.isPending ? 'Activation...' : 'Activer la maintenance'}
            </button>
          </div>
        ) : (
          <button
            onClick={() => desactiverMutation.mutate()}
            disabled={desactiverMutation.isPending}
            className="flex items-center gap-2 bg-green-600 hover:bg-green-700 text-white px-5 py-2.5 rounded-xl text-sm font-medium transition-colors disabled:opacity-50"
          >
            <Power className="w-4 h-4" />
            {desactiverMutation.isPending ? 'Désactivation...' : 'Désactiver la maintenance'}
          </button>
        )}
      </div>

      {/* Logs */}
      {logs.length > 0 && (
        <div className="bg-gray-800 rounded-2xl p-6">
          <div className="flex items-center gap-3 mb-4">
            <Settings className="w-5 h-5 text-gray-400" />
            <h2 className="font-semibold text-gray-100">Historique</h2>
          </div>
          <div className="space-y-2">
            {logs.slice(0, 20).map((log: { id?: number; message?: string; type?: string; created_at?: string }, i: number) => (
              <div key={log.id || i} className="flex items-start gap-3 text-sm p-3 bg-gray-700 rounded-xl">
                <div className="flex-1">
                  <div className="text-gray-200">{log.message || JSON.stringify(log)}</div>
                  {log.created_at && (
                    <div className="text-xs text-gray-500 mt-1">{new Date(log.created_at).toLocaleString('fr-FR')}</div>
                  )}
                </div>
                {log.type && (
                  <span className={`badge text-xs flex-shrink-0 ${log.type === 'activation' ? 'bg-red-900 text-red-300' : 'bg-green-900 text-green-300'}`}>
                    {log.type}
                  </span>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
