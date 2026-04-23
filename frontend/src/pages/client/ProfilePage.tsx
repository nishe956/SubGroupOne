import { useState, FormEvent } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { User, Lock, Shield } from 'lucide-react';
import api from '@/lib/api';
import { useAuth } from '@/contexts/AuthContext';
import { CompagnieAssurance } from '@/types';
import toast from 'react-hot-toast';

export default function ProfilePage() {
  const { user, updateUser } = useAuth();
  const qc = useQueryClient();
  const [form, setForm] = useState({
    first_name: user?.first_name || '',
    last_name: user?.last_name || '',
    telephone: user?.telephone || '',
    adresse: user?.adresse || '',
    date_naissance: user?.date_naissance || '',
  });
  const [pwdForm, setPwdForm] = useState({ old_password: '', new_password: '', confirm_password: '' });
  const [showPwd, setShowPwd] = useState(false);
  const [assuranceForm, setAssuranceForm] = useState({
    compagnie_assurance: user?.compagnie_assurance ? String(user.compagnie_assurance) : '',
    numero_police: user?.numero_police || '',
  });

  const { data: compagnies = [] } = useQuery<CompagnieAssurance[]>({
    queryKey: ['compagnies-assurance'],
    queryFn: () => api.get('/assurance/compagnies/').then(r => r.data?.results || r.data),
  });

  const profileMutation = useMutation({
    mutationFn: (data: typeof form) => api.put('/users/profil/', data),
    onSuccess: (res) => {
      updateUser(res.data);
      qc.invalidateQueries({ queryKey: ['profil'] });
      toast.success('Profil mis à jour');
    },
    onError: () => toast.error('Erreur lors de la mise à jour'),
  });

  const pwdMutation = useMutation({
    mutationFn: (data: typeof pwdForm) => api.post('/users/change-password/', data),
    onSuccess: () => {
      toast.success('Mot de passe modifié');
      setPwdForm({ old_password: '', new_password: '', confirm_password: '' });
    },
    onError: (err: unknown) => {
      const msg = (err as { response?: { data?: { detail?: string; message?: string } } })?.response?.data?.detail || 'Erreur';
      toast.error(msg);
    },
  });

  const assuranceMutation = useMutation({
    mutationFn: (data: typeof assuranceForm) => api.patch('/users/profil/', {
      compagnie_assurance: data.compagnie_assurance ? Number(data.compagnie_assurance) : null,
      numero_police: data.numero_police,
    }),
    onSuccess: (res) => {
      updateUser(res.data);
      toast.success('Assurance mise à jour');
    },
    onError: () => toast.error('Erreur lors de la mise à jour'),
  });

  const handleProfile = (e: FormEvent) => { e.preventDefault(); profileMutation.mutate(form); };
  const handlePwd = (e: FormEvent) => {
    e.preventDefault();
    if (pwdForm.new_password !== pwdForm.confirm_password) { toast.error('Les mots de passe ne correspondent pas'); return; }
    pwdMutation.mutate(pwdForm);
  };

  return (
    <div className="max-w-2xl">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Mon profil</h1>

      <div className="card mb-6">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 bg-primary-100 rounded-xl flex items-center justify-center">
            <User className="w-5 h-5 text-primary-600" />
          </div>
          <h2 className="font-semibold text-gray-900">Informations personnelles</h2>
        </div>
        <form onSubmit={handleProfile} className="space-y-3">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Nom d'utilisateur</label>
            <input value={user?.username || ''} disabled className="input-field bg-gray-50 text-gray-400 cursor-not-allowed" />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Prénom</label>
              <input value={form.first_name} onChange={e => setForm(f => ({ ...f, first_name: e.target.value }))} className="input-field" required />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Nom</label>
              <input value={form.last_name} onChange={e => setForm(f => ({ ...f, last_name: e.target.value }))} className="input-field" required />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
            <input value={user?.email || ''} disabled className="input-field bg-gray-50 text-gray-400 cursor-not-allowed" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Téléphone</label>
            <input value={form.telephone} onChange={e => setForm(f => ({ ...f, telephone: e.target.value }))} className="input-field" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Adresse</label>
            <input value={form.adresse} onChange={e => setForm(f => ({ ...f, adresse: e.target.value }))} className="input-field" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Date de naissance</label>
            <input type="date" value={form.date_naissance} onChange={e => setForm(f => ({ ...f, date_naissance: e.target.value }))} className="input-field" />
          </div>
          <button type="submit" disabled={profileMutation.isPending} className="btn-primary">
            {profileMutation.isPending ? 'Sauvegarde...' : 'Enregistrer'}
          </button>
        </form>
      </div>

      <div className="card mb-6">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 bg-green-100 rounded-xl flex items-center justify-center">
            <Shield className="w-5 h-5 text-green-600" />
          </div>
          <h2 className="font-semibold text-gray-900">Mon assurance</h2>
        </div>
        <form onSubmit={e => { e.preventDefault(); assuranceMutation.mutate(assuranceForm); }} className="space-y-3">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Compagnie d'assurance</label>
            <select
              value={assuranceForm.compagnie_assurance}
              onChange={e => setAssuranceForm(f => ({ ...f, compagnie_assurance: e.target.value }))}
              className="input-field"
            >
              <option value="">Aucune assurance</option>
              {compagnies.map(c => (
                <option key={c.id} value={c.id}>{c.nom} — {c.taux_prise_charge}% pris en charge</option>
              ))}
            </select>
          </div>
          {assuranceForm.compagnie_assurance && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Numéro de police / adhérent</label>
              <input
                value={assuranceForm.numero_police}
                onChange={e => setAssuranceForm(f => ({ ...f, numero_police: e.target.value }))}
                className="input-field"
                placeholder="Ex: ASS-2024-00123"
              />
            </div>
          )}
          {assuranceForm.compagnie_assurance && (
            <div className="bg-green-50 border border-green-200 rounded-xl p-3 text-sm text-green-700">
              Votre assurance sera appliquée automatiquement lors de vos commandes.
            </div>
          )}
          <button type="submit" disabled={assuranceMutation.isPending} className="btn-primary">
            {assuranceMutation.isPending ? 'Sauvegarde...' : 'Enregistrer mon assurance'}
          </button>
        </form>
      </div>

      <div className="card">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 bg-orange-100 rounded-xl flex items-center justify-center">
            <Lock className="w-5 h-5 text-orange-600" />
          </div>
          <h2 className="font-semibold text-gray-900">Changer le mot de passe</h2>
        </div>
        <button onClick={() => setShowPwd(!showPwd)} className="text-sm text-primary-600 hover:underline mb-3">
          {showPwd ? 'Masquer' : 'Modifier le mot de passe'}
        </button>
        {showPwd && (
          <form onSubmit={handlePwd} className="space-y-3">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Mot de passe actuel</label>
              <input type="password" value={pwdForm.old_password} onChange={e => setPwdForm(f => ({ ...f, old_password: e.target.value }))} className="input-field" required />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Nouveau mot de passe</label>
              <input type="password" value={pwdForm.new_password} onChange={e => setPwdForm(f => ({ ...f, new_password: e.target.value }))} className="input-field" required minLength={8} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Confirmer le nouveau mot de passe</label>
              <input type="password" value={pwdForm.confirm_password} onChange={e => setPwdForm(f => ({ ...f, confirm_password: e.target.value }))} className="input-field" required />
            </div>
            <button type="submit" disabled={pwdMutation.isPending} className="btn-primary">
              {pwdMutation.isPending ? 'Modification...' : 'Modifier le mot de passe'}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
