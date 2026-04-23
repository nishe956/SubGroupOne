import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { UserX, UserCheck, Search, Trash2 } from 'lucide-react';
import api from '@/lib/api';
import { User } from '@/types';
import { useAuth } from '@/contexts/AuthContext';
import toast from 'react-hot-toast';

export default function AdminUsers() {
  const qc = useQueryClient();
  const { user: me } = useAuth();
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('');

  const { data, isLoading } = useQuery({
    queryKey: ['admin-users', roleFilter],
    queryFn: () => api.get('/users/liste/', { params: { role: roleFilter || undefined } }).then(r => r.data),
  });

  const users: User[] = data?.results || data || [];

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

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-100 mb-6">Gestion des utilisateurs</h1>
      <div className="bg-gray-800 rounded-2xl p-4 mb-4 flex gap-3 flex-wrap">
        <div className="relative flex-1 min-w-48">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-full bg-gray-700 text-white rounded-xl pl-9 pr-4 py-2.5 text-sm outline-none border border-gray-600 focus:border-primary-500"
            placeholder="Rechercher..."
          />
        </div>
        <select
          value={roleFilter}
          onChange={e => setRoleFilter(e.target.value)}
          className="bg-gray-700 text-white rounded-xl px-3 py-2.5 text-sm outline-none border border-gray-600"
        >
          <option value="">Tous les rôles</option>
          <option value="client">Clients</option>
          <option value="opticien">Opticiens</option>
          <option value="admin">Admins</option>
        </select>
      </div>

      <div className="bg-gray-800 rounded-2xl overflow-hidden overflow-x-auto">
        <table className="w-full min-w-[600px]">
          <thead className="border-b border-gray-700">
            <tr>
              {['Utilisateur', 'Email', 'Rôle', 'Statut', 'Actions'].map(h => (
                <th key={h} className="text-left text-xs font-medium text-gray-400 uppercase tracking-wider px-4 py-3">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-700">
            {isLoading ? [...Array(5)].map((_, i) => (
              <tr key={i}><td colSpan={5} className="px-4 py-3"><div className="h-4 bg-gray-700 animate-pulse rounded" /></td></tr>
            )) : filtered.map(u => (
              <tr key={u.id} className="hover:bg-gray-750">
                <td className="px-4 py-3 text-sm font-medium text-white">{u.first_name} {u.last_name}</td>
                <td className="px-4 py-3 text-sm text-gray-400">{u.email}</td>
                <td className="px-4 py-3">
                  <span className={`badge text-xs ${u.role === 'admin' ? 'bg-red-900 text-red-300' : u.role === 'opticien' ? 'bg-purple-900 text-purple-300' : 'bg-blue-900 text-blue-300'}`}>
                    {u.role}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <span className={`badge ${u.is_active ? 'bg-green-900 text-green-300' : 'bg-gray-700 text-gray-400'}`}>
                    {u.is_active ? 'Actif' : 'Inactif'}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => toggleMutation.mutate(u)}
                      disabled={toggleMutation.isPending}
                      title={u.is_active ? 'Désactiver' : 'Activer'}
                      className={`p-1.5 rounded-lg transition-colors ${u.is_active ? 'text-yellow-400 hover:bg-yellow-900/30' : 'text-green-400 hover:bg-green-900/30'}`}
                    >
                      {u.is_active ? <UserX className="w-4 h-4" /> : <UserCheck className="w-4 h-4" />}
                    </button>
                    {u.id !== me?.id && (
                      <button
                        onClick={() => handleDelete(u)}
                        disabled={deleteMutation.isPending}
                        title="Supprimer"
                        className="p-1.5 rounded-lg text-red-400 hover:bg-red-900/30 transition-colors"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
