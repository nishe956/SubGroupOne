import { useState, FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Eye, EyeOff, UserPlus, User, Store, CheckCircle } from 'lucide-react';
import api from '@/lib/api';
import { useAuth } from '@/contexts/AuthContext';
import toast from 'react-hot-toast';

type Step = 0 | 1 | 2;

export default function RegisterPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [step, setStep] = useState<Step>(0);
  const [role, setRole] = useState<'client' | 'opticien'>('client');
  const [form, setForm] = useState({
    username: '', first_name: '', last_name: '', email: '',
    password: '', telephone: '', adresse: '', date_naissance: '',
    boutique_nom: '', boutique_adresse: '', boutique_telephone: '',
  });
  const [showPwd, setShowPwd] = useState(false);
  const [loading, setLoading] = useState(false);
  const [emailError, setEmailError] = useState('');

  const set = (key: string) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setForm(f => ({ ...f, [key]: e.target.value }));

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setEmailError('');
    setLoading(true);
    try {
      const payload: Record<string, string> = {
        username: form.username,
        first_name: form.first_name,
        last_name: form.last_name,
        email: form.email,
        password: form.password,
        role,
        telephone: form.telephone,
        adresse: form.adresse,
        date_naissance: form.date_naissance,
      };
      if (role === 'opticien') {
        payload.boutique_nom = form.boutique_nom;
        payload.boutique_adresse = form.boutique_adresse;
        payload.boutique_telephone = form.boutique_telephone;
      }
      await api.post('/users/register/', payload);
      setStep(2);
      setTimeout(async () => {
        try {
          await login(form.username, form.password);
          navigate('/');
        } catch {
          navigate('/login');
        }
      }, 2000);
    } catch (err: unknown) {
      const data = (err as { response?: { data?: Record<string, string[]> } })?.response?.data;
      if (data?.email) {
        setEmailError(data.email[0]);
      } else {
        const msg = data ? Object.values(data).flat().join(' ') : "Erreur lors de l'inscription";
        toast.error(msg);
      }
    } finally {
      setLoading(false);
    }
  };

  if (step === 2) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-primary-50 to-blue-100 flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl shadow-xl p-10 w-full max-w-md text-center">
          <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <CheckCircle className="w-8 h-8 text-green-600" />
          </div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Compte créé !</h2>
          <p className="text-gray-500 text-sm">Vous allez être redirigé automatiquement...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-50 to-blue-100 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-xl p-8 w-full max-w-lg">
        <div className="flex items-center gap-2 mb-6">
          <div className="w-10 h-10 bg-primary-600 rounded-xl flex items-center justify-center">
            <Eye className="w-6 h-6 text-white" />
          </div>
          <span className="font-bold text-xl text-gray-900">Lunette Pro</span>
        </div>
        <h1 className="text-2xl font-bold text-gray-900 mb-1">Créer un compte</h1>
        <p className="text-gray-500 text-sm mb-5">Rejoignez Lunette Pro dès aujourd'hui</p>

        {step === 0 && (
          <div>
            <p className="text-sm font-medium text-gray-700 mb-4">Je suis :</p>
            <div className="grid grid-cols-2 gap-4 mb-6">
              <button
                onClick={() => { setRole('client'); setStep(1); }}
                className={`p-6 rounded-2xl border-2 flex flex-col items-center gap-3 transition-all ${role === 'client' ? 'border-primary-500 bg-primary-50' : 'border-gray-200 hover:border-primary-300'}`}
              >
                <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center">
                  <User className="w-6 h-6 text-blue-600" />
                </div>
                <div>
                  <div className="font-semibold text-gray-900">Client</div>
                  <div className="text-xs text-gray-500 mt-1">Parcourez le catalogue et commandez vos lunettes</div>
                </div>
              </button>
              <button
                onClick={() => { setRole('opticien'); setStep(1); }}
                className={`p-6 rounded-2xl border-2 flex flex-col items-center gap-3 transition-all ${role === 'opticien' ? 'border-primary-500 bg-primary-50' : 'border-gray-200 hover:border-primary-300'}`}
              >
                <div className="w-12 h-12 bg-purple-100 rounded-xl flex items-center justify-center">
                  <Store className="w-6 h-6 text-purple-600" />
                </div>
                <div>
                  <div className="font-semibold text-gray-900">Opticien</div>
                  <div className="text-xs text-gray-500 mt-1">Vendez vos montures et gérez votre boutique</div>
                </div>
              </button>
            </div>
          </div>
        )}

        {step === 1 && (
          <form onSubmit={handleSubmit} className="space-y-3">
            <div className="flex items-center gap-2 mb-4">
              <span className="text-sm text-gray-500">Compte {role === 'opticien' ? 'Opticien' : 'Client'}</span>
              <button type="button" onClick={() => setStep(0)} className="text-xs text-primary-600 hover:underline ml-auto">Changer</button>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Nom d'utilisateur</label>
              <input value={form.username} onChange={set('username')} className="input-field" placeholder="" required />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Prénom</label>
                <input value={form.first_name} onChange={set('first_name')} className="input-field" placeholder="" required />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Nom</label>
                <input value={form.last_name} onChange={set('last_name')} className="input-field" placeholder="" required />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
              <input
                type="email"
                value={form.email}
                onChange={e => { set('email')(e); setEmailError(''); }}
                className={`input-field ${emailError ? 'border-red-500 focus:ring-red-500' : ''}`}
                placeholder="vous@example.com"
                required
              />
              {emailError && (
                <p className="mt-1 text-xs text-red-600">{emailError}</p>
              )}
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Téléphone</label>
              <input value={form.telephone} onChange={set('telephone')} className="input-field" placeholder="+226 70 00 00 00" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Date de naissance</label>
              <input type="date" value={form.date_naissance} onChange={set('date_naissance')} className="input-field" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Mot de passe</label>
              <div className="relative">
                <input
                  type={showPwd ? 'text' : 'password'}
                  value={form.password}
                  onChange={set('password')}
                  className="input-field pr-10"
                  placeholder="Min. 8 caractères"
                  required
                  minLength={8}
                />
                <button type="button" onClick={() => setShowPwd(!showPwd)} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400">
                  {showPwd ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            {role === 'opticien' && (
              <div className="border-t pt-3 mt-3 space-y-3">
                <p className="text-sm font-semibold text-gray-700">Informations de la boutique</p>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Nom de la boutique</label>
                  <input value={form.boutique_nom} onChange={set('boutique_nom')} className="input-field" placeholder="Optique Vision Plus" required={role === 'opticien'} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Adresse boutique</label>
                  <input value={form.boutique_adresse} onChange={set('boutique_adresse')} className="input-field" placeholder="Secteur 10, Avenue Kwamé N'Krumah, Ouagadougou" required={role === 'opticien'} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Téléphone boutique</label>
                  <input value={form.boutique_telephone} onChange={set('boutique_telephone')} className="input-field" placeholder="+226 25 00 00 00" />
                </div>
              </div>
            )}

            <button type="submit" disabled={loading} className="btn-primary w-full flex items-center justify-center gap-2 mt-2">
              {loading ? <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" /> : <UserPlus className="w-4 h-4" />}
              {loading ? 'Création...' : 'Créer mon compte'}
            </button>
          </form>
        )}

        <p className="text-center text-sm text-gray-500 mt-5">
          Déjà un compte ?{' '}
          <Link to="/login" className="text-primary-600 font-medium hover:underline">Se connecter</Link>
        </p>
      </div>
    </div>
  );
}
