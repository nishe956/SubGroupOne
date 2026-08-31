import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { UserX, UserCheck, Search, Trash2 } from 'lucide-react';
import api, { listeDepuis } from '@/lib/api';
import { User } from '@/types';
import { useAuth } from '@/contexts/AuthContext';
import toast from 'react-hot-toast';
import { Badge, Tableau, Colonne, EnTetePage, Avatar, Ton } from '@/components/admin';

const ROLES: Record<string, { libelle: string; ton: Ton }> = {
  admin:    { libelle: 'Admin',    ton: 'danger' },
  opticien: { libelle: 'Opticien', ton: 'accent' },
  client:   { libelle: 'Client',   ton: 'info'   },
};

export default function AdminUsers() {
  const qc = useQueryClient();
  const { user: me } = useAuth();
  const [params] = useSearchParams();
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('');

  // La barre de recherche de l'en-tête dépose sa requête dans l'URL : on la
  // reprend telle quelle pour que le lien reste partageable et rechargeable.
  const requeteUrl = params.get('q') ?? '';
  useEffect(() => { if (requeteUrl) setSearch(requeteUrl); }, [requeteUrl]);

  const { data, isLoading } = useQuery({
    queryKey: ['admin-users', roleFilter],
    queryFn: () => api.get('/users/liste/', { params: { role: roleFilter || undefined, page_size: 100 } }).then(r => listeDepuis<User>(r.data)),
  });

  const users: User[] = data ?? [];

  const toggleMutation = useMutation({
    mutationFn: (u: User) => api.patch(`/users/${u.id}/`, { is_active: !u.is_active }),
    onSuccess: () => { toast.success('Statut modifié'); qc.invalidateQueries({ queryKey: ['admin-users'] }); },
    onError: () => toast.error('Erreur'),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => api.delete(`/users/${id}/`),
    onSuccess: () => { toast.success('Utilisateur supprimé'); qc.invalidateQueries({ queryKey: ['admin-users'] }); },
    onError: () => toast.error('Erreur lors de la suppression'),
  });

  const handleDelete = (u: User) => {
    if (u.id === me?.id) { toast.error('Vous ne pouvez pas vous supprimer vous-même'); return; }
    if (confirm(`Supprimer ${u.first_name} ${u.last_name} ? Cette action est irréversible.`)) {
      deleteMutation.mutate(u.id);
    }
  };

  const filtered = users.filter(u =>
    !search ||
    `${u.first_name} ${u.last_name} ${u.username} ${u.email}`.toLowerCase().includes(search.toLowerCase())
  );

  const colonnes: Colonne<User>[] = [
    {
      cle: 'utilisateur', libelle: 'Utilisateur',
      rendu: u => {
        const nom = `${u.first_name ?? ''} ${u.last_name ?? ''}`.trim();
        return (
          <div className="flex items-center gap-3">
            <Avatar nom={nom || u.username} taille="sm" />
            <div className="min-w-0">
              <div className="font-medium text-gray-900 truncate">{nom || u.username}</div>
              <div className="text-xs text-gray-400 truncate">@{u.username}</div>
            </div>
          </div>
        );
      },
    },
    { cle: 'email', libelle: 'Email', rendu: u => <span className="text-gray-500">{u.email || '—'}</span> },
    {
      cle: 'role', libelle: 'Rôle',
      rendu: u => {
        const r = ROLES[u.role] ?? { libelle: u.role, ton: 'neutre' as Ton };
        return <Badge ton={r.ton}>{r.libelle}</Badge>;
      },
    },
    {
      cle: 'statut', libelle: 'Statut',
      rendu: u => <Badge ton={u.is_active ? 'succes' : 'neutre'}>{u.is_active ? 'Actif' : 'Inactif'}</Badge>,
    },
    {
      cle: 'actions', libelle: 'Actions', align: 'right', className: 'w-28',
      rendu: u => (
        <div className="flex items-center justify-end gap-1">
          <button
            onClick={() => toggleMutation.mutate(u)}
            disabled={toggleMutation.isPending}
            title={u.is_active ? 'Désactiver le compte' : 'Activer le compte'}
            aria-label={u.is_active ? 'Désactiver le compte' : 'Activer le compte'}
            className={`p-2 rounded-lg transition-colors ${u.is_active ? 'text-amber-600 hover:bg-amber-50' : 'text-emerald-600 hover:bg-emerald-50'}`}
          >
            {u.is_active ? <UserX className="w-4 h-4" /> : <UserCheck className="w-4 h-4" />}
          </button>
          {u.id !== me?.id && (
            <button
              onClick={() => handleDelete(u)}
              disabled={deleteMutation.isPending}
              title="Supprimer"
              aria-label="Supprimer l'utilisateur"
              className="p-2 rounded-lg text-red-500 hover:bg-red-50 transition-colors"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          )}
        </div>
      ),
    },
  ];

  return (
    <div>
      <EnTetePage
        titre="Utilisateurs"
        sousTitre={`${filtered.length} compte${filtered.length > 1 ? 's' : ''} ${search || roleFilter ? 'correspondant au filtre' : 'sur la plateforme'}`}
      />

      <div className="bg-white rounded-2xl border border-gray-100 shadow-card p-4 mb-4 flex gap-3 flex-wrap">
        <div className="relative flex-1 min-w-[200px]">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            aria-label="Rechercher un utilisateur"
            className="champ-admin pl-9"
            placeholder="Nom, identifiant ou email..."
          />
        </div>
        <select
          value={roleFilter}
          onChange={e => setRoleFilter(e.target.value)}
          aria-label="Filtrer par rôle"
          className="champ-admin w-auto"
        >
          <option value="">Tous les rôles</option>
          <option value="client">Clients</option>
          <option value="opticien">Opticiens</option>
          <option value="admin">Admins</option>
        </select>
      </div>

      <Tableau
        colonnes={colonnes}
        lignes={filtered}
        cleLigne={u => u.id}
        chargement={isLoading}
        parPage={10}
        vide={{ titre: 'Aucun utilisateur', texte: 'Aucun compte ne correspond à cette recherche.' }}
      />
    </div>
  );
}
