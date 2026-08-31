import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { CircleAlert, CircleCheck, Power, History } from 'lucide-react';
import api from '@/lib/api';
import { MaintenanceStatut } from '@/types';
import toast from 'react-hot-toast';
import { Carte, EnTeteCarte, Badge, EnTetePage } from '@/components/admin';

interface LogMaintenance { id?: number; message?: string; type?: string; created_at?: string }

/** L'API renvoie « activation » / « desactivation » : on les nomme côté métier. */
const LIBELLES_LOG: Record<string, string> = {
  activation: 'Fermeture du site',
  desactivation: 'Réouverture',
};

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

  const logs: LogMaintenance[] = logsData?.results || logsData || [];

  const rafraichir = () => {
    qc.invalidateQueries({ queryKey: ['maintenance-statut'] });
    qc.invalidateQueries({ queryKey: ['maintenance-logs'] });
  };

  const activerMutation = useMutation({
    mutationFn: () => api.post('/maintenance/activer/', { message }),
    onSuccess: () => { toast.success('Mode maintenance activé'); rafraichir(); },
    onError: () => toast.error("Erreur lors de l'activation"),
  });

  const desactiverMutation = useMutation({
    mutationFn: () => api.post('/maintenance/desactiver/'),
    onSuccess: () => { toast.success('Mode maintenance désactivé'); rafraichir(); },
    onError: () => toast.error('Erreur lors de la désactivation'),
  });

  if (isLoading) {
    return (
      <div className="flex justify-center py-24">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-accent-500" />
      </div>
    );
  }

  const actif = !!statut?.actif;

  return (
    <div className="max-w-3xl">
      <EnTetePage titre="Maintenance" sousTitre="Coupe l'accès au site pour tous les visiteurs, sauf l'administration." />

      {/* L'état courant occupe le haut de page : c'est la seule information
          qu'on vient vérifier ici, avant même d'agir. */}
      <Carte className={`mb-4 ${actif ? 'border-red-200 bg-red-50/40' : ''}`}>
        <div className="flex items-start gap-4">
          <div className={`w-12 h-12 rounded-full flex items-center justify-center flex-shrink-0 ${actif ? 'bg-red-100 text-red-600' : 'bg-emerald-50 text-emerald-600'}`}>
            {actif ? <CircleAlert className="w-6 h-6" strokeWidth={1.75} /> : <CircleCheck className="w-6 h-6" strokeWidth={1.75} />}
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <span className="font-bold text-gray-900 text-lg">
                {actif ? 'Mode maintenance actif' : 'Système opérationnel'}
              </span>
              <Badge ton={actif ? 'danger' : 'succes'}>{actif ? 'Site fermé' : 'Site ouvert'}</Badge>
            </div>
            {statut?.message && <p className="text-sm text-gray-600 mt-1">{statut.message}</p>}
            {statut?.debut && (
              <p className="text-xs text-gray-400 mt-1">Depuis le {new Date(statut.debut).toLocaleString('fr-FR')}</p>
            )}
          </div>
        </div>

        <div className="mt-5 pt-5 border-t border-gray-100">
          {!actif ? (
            <div className="space-y-3">
              <div>
                <label htmlFor="message-maintenance" className="label">Message affiché aux visiteurs (optionnel)</label>
                <input
                  id="message-maintenance"
                  value={message}
                  onChange={e => setMessage(e.target.value)}
                  className="champ-admin"
                  placeholder="Le site est en maintenance pour amélioration..."
                />
              </div>
              <button
                onClick={() => activerMutation.mutate()}
                disabled={activerMutation.isPending}
                className="inline-flex items-center gap-2 bg-red-600 hover:bg-red-700 text-white px-5 py-2.5 rounded-xl text-sm font-medium transition-colors disabled:opacity-50"
              >
                <Power className="w-4 h-4" />
                {activerMutation.isPending ? 'Activation...' : 'Activer la maintenance'}
              </button>
            </div>
          ) : (
            <button
              onClick={() => desactiverMutation.mutate()}
              disabled={desactiverMutation.isPending}
              className="inline-flex items-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white px-5 py-2.5 rounded-xl text-sm font-medium transition-colors disabled:opacity-50"
            >
              <Power className="w-4 h-4" />
              {desactiverMutation.isPending ? 'Désactivation...' : 'Rouvrir le site'}
            </button>
          )}
        </div>
      </Carte>

      {logs.length > 0 && (
        <Carte>
          <EnTeteCarte
            titre="Historique"
            sousTitre="20 dernières bascules"
            action={<History className="w-4 h-4 text-gray-300" />}
          />
          <ul className="space-y-2">
            {logs.slice(0, 20).map((log, i) => (
              <li key={log.id ?? i} className="flex items-start gap-3 rounded-xl bg-gray-50 px-4 py-3">
                <div className="flex-1 min-w-0">
                  <div className="text-sm text-gray-700">{log.message || 'Bascule du mode maintenance'}</div>
                  {log.created_at && (
                    <div className="text-xs text-gray-400 mt-0.5">{new Date(log.created_at).toLocaleString('fr-FR')}</div>
                  )}
                </div>
                {log.type && (
                  <Badge ton={log.type === 'activation' ? 'danger' : 'succes'}>
                    {LIBELLES_LOG[log.type] ?? log.type}
                  </Badge>
                )}
              </li>
            ))}
          </ul>
        </Carte>
      )}
    </div>
  );
}
