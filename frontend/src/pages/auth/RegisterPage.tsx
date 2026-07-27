import { useState, FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  Eye, EyeOff, User, Store, CheckCircle, Check, Clock,
  ArrowLeft, ArrowRight, UserPlus, Building2, ShieldCheck, Sparkles, Glasses,
} from 'lucide-react';
import api from '@/lib/api';
import { useAuth } from '@/contexts/AuthContext';
import toast from 'react-hot-toast';
import { passwordStrength } from '@/utils/passwordStrength';
import GoogleAuthButton from '@/components/auth/GoogleAuthButton';

type Role = 'client' | 'opticien';

const FEATURES = [
  { icon: Glasses, title: 'Catalogue complet', text: 'Des centaines de montures des meilleures boutiques.' },
  { icon: Sparkles, title: 'Essayage virtuel', text: 'Essayez vos montures en ligne avant de commander.' },
  { icon: ShieldCheck, title: 'Ordonnances sécurisées', text: 'Vos données médicales protégées et prises en charge par votre assurance.' },
];

export default function RegisterPage() {
  const { login, loginWithGoogle } = useAuth();
  const navigate = useNavigate();
  const [role, setRole] = useState<Role | null>(null);
  const [step, setStep] = useState(0); // 0 = choix du profil, 1 = compte, 2 = boutique (opticien)
  const [done, setDone] = useState(false);
  const [form, setForm] = useState({
    username: '', first_name: '', last_name: '', email: '',
    password: '', telephone: '', adresse: '', date_naissance: '',
    boutique_nom: '', boutique_adresse: '', boutique_telephone: '', boutique_description: '',
  });
  const [showPwd, setShowPwd] = useState(false);
  const [loading, setLoading] = useState(false);
  const [emailError, setEmailError] = useState('');

  const isOpticien = role === 'opticien';
  const steps = isOpticien
    ? ['Profil', 'Votre compte', 'Votre boutique']
    : ['Profil', 'Votre compte'];
  const strength = passwordStrength(form.password);

  const set = (key: string) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
    setForm(f => ({ ...f, [key]: e.target.value }));

  const submit = async () => {
    setEmailError('');
    setLoading(true);
    try {
      const payload: Record<string, string> = {
        username: form.username,
        first_name: form.first_name,
        last_name: form.last_name,
        email: form.email,
        password: form.password,
        role: role || 'client',
        telephone: form.telephone,
        adresse: form.adresse,
        date_naissance: form.date_naissance,
      };
      if (isOpticien) {
        payload.boutique_nom = form.boutique_nom;
        payload.boutique_adresse = form.boutique_adresse;
        payload.boutique_telephone = form.boutique_telephone;
        payload.boutique_description = form.boutique_description;
      }
      await api.post('/users/register/', payload);
      setDone(true);
      // Un opticien doit être validé par un administrateur : pas de connexion automatique.
      if (isOpticien) return;
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
        setStep(1); // revenir à l'étape contenant le champ email
      } else {
        const msg = data ? Object.values(data).flat().join(' ') : "Erreur lors de l'inscription";
        toast.error(msg);
      }
    } finally {
      setLoading(false);
    }
  };

  const handleAccountSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (isOpticien) setStep(2);
    else submit();
  };

  const handleBoutiqueSubmit = (e: FormEvent) => {
    e.preventDefault();
    submit();
  };

  const handleGoogleSuccess = async (credential: string) => {
    try {
      await loginWithGoogle(credential);
      toast.success('Bienvenue !');
      navigate('/');
    } catch {
      toast.error('La connexion avec Google a échoué.');
    }
  };

  if (done && isOpticien) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-primary-50 to-blue-100 flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl shadow-xl p-10 w-full max-w-md text-center animate-fade-up">
          <div className="w-16 h-16 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <Clock className="w-8 h-8 text-amber-600" />
          </div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Demande envoyée !</h2>
          <p className="text-gray-500 text-sm mb-6">
            Votre demande de compte opticien a bien été enregistrée. Un administrateur doit la
            valider avant que vous puissiez vous connecter. Vous serez informé dès l'activation
            de votre boutique.
          </p>
          <Link to="/login" className="btn-primary w-full">Retour à la connexion</Link>
        </div>
      </div>
    );
  }

  if (done) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-primary-50 to-blue-100 flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl shadow-xl p-10 w-full max-w-md text-center animate-fade-up">
          <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <CheckCircle className="w-8 h-8 text-green-600" />
          </div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Bienvenue sur Lunette Pro !</h2>
          <p className="text-gray-500 text-sm">
            Votre compte client a été créé. Connexion en cours...
          </p>
          <div className="mt-6 flex justify-center">
            <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-primary-600" />
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex bg-white">
      {/* Panneau de marque */}
      <div className="hidden lg:flex lg:w-[45%] xl:w-2/5 bg-gradient-to-br from-primary-700 via-primary-600 to-primary-900 text-white flex-col justify-between p-12 relative overflow-hidden">
        <div className="absolute -top-24 -right-24 w-96 h-96 bg-white/5 rounded-full" />
        <div className="absolute -bottom-32 -left-16 w-80 h-80 bg-white/5 rounded-full" />

        <Link to="/" className="flex items-center gap-3 relative">
          <div className="w-11 h-11 bg-white/15 backdrop-blur rounded-xl flex items-center justify-center">
            <Eye className="w-6 h-6 text-white" />
          </div>
          <span className="font-bold text-2xl">Lunette Pro</span>
        </Link>

        <div className="relative">
          <h2 className="text-3xl xl:text-4xl font-bold leading-tight mb-4">
            {isOpticien
              ? 'Développez votre boutique d’optique en ligne'
              : 'Votre opticien, directement en ligne'}
          </h2>
          <p className="text-primary-100 mb-10 text-lg">
            {isOpticien
              ? 'Gérez vos montures, vos commandes et vos clients depuis une seule plateforme.'
              : 'Commandez vos lunettes, gérez vos ordonnances et celles de votre famille en toute simplicité.'}
          </p>
          <ul className="space-y-6">
            {FEATURES.map(({ icon: Icon, title, text }) => (
              <li key={title} className="flex items-start gap-4">
                <div className="w-10 h-10 bg-white/10 rounded-lg flex items-center justify-center shrink-0">
                  <Icon className="w-5 h-5" />
                </div>
                <div>
                  <div className="font-semibold">{title}</div>
                  <div className="text-sm text-primary-100">{text}</div>
                </div>
              </li>
            ))}
          </ul>
        </div>

        <p className="text-sm text-primary-200 relative">
          © {new Date().getFullYear()} Lunette Pro — La vision au bout des doigts.
        </p>
      </div>

      {/* Zone formulaire */}
      <div className="flex-1 flex flex-col overflow-y-auto">
        <div className="lg:hidden flex items-center gap-2 p-5 border-b border-gray-100">
          <div className="w-9 h-9 bg-primary-600 rounded-xl flex items-center justify-center">
            <Eye className="w-5 h-5 text-white" />
          </div>
          <span className="font-bold text-lg text-gray-900">Lunette Pro</span>
        </div>

        <div className="flex-1 flex items-center justify-center p-6 sm:p-10">
          <div className="w-full max-w-md">
            {/* Barre de progression */}
            <div className="flex items-center mb-8">
              {steps.map((label, i) => (
                <div key={label} className={`flex items-center ${i < steps.length - 1 ? 'flex-1' : ''}`}>
                  <div className="flex flex-col items-center">
                    <div
                      className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-semibold transition-all ${
                        i < step
                          ? 'bg-primary-600 text-white'
                          : i === step
                            ? 'bg-primary-600 text-white ring-4 ring-primary-100'
                            : 'bg-gray-100 text-gray-400'
                      }`}
                    >
                      {i < step ? <Check className="w-4 h-4" /> : i + 1}
                    </div>
                    <span className={`text-[11px] mt-1.5 font-medium whitespace-nowrap ${i <= step ? 'text-primary-700' : 'text-gray-400'}`}>
                      {label}
                    </span>
                  </div>
                  {i < steps.length - 1 && (
                    <div className={`flex-1 h-0.5 mx-2 mb-5 rounded ${i < step ? 'bg-primary-600' : 'bg-gray-200'}`} />
                  )}
                </div>
              ))}
            </div>

            {/* Étape 0 : choix du profil */}
            {step === 0 && (
              <div className="animate-fade-up">
                <h1 className="text-2xl font-bold text-gray-900 mb-1">Créer un compte</h1>
                <p className="text-gray-500 text-sm mb-6">Choisissez le type de compte qui vous correspond.</p>
                <div className="space-y-3">
                  {([
                    {
                      value: 'client' as Role, icon: User, iconBg: 'bg-blue-100 text-blue-600',
                      title: 'Client',
                      desc: 'Parcourez le catalogue, essayez et commandez vos lunettes en ligne.',
                    },
                    {
                      value: 'opticien' as Role, icon: Store, iconBg: 'bg-purple-100 text-purple-600',
                      title: 'Opticien',
                      desc: 'Vendez vos montures, gérez votre boutique et vos commandes.',
                    },
                  ]).map(({ value, icon: Icon, iconBg, title, desc }) => (
                    <button
                      key={value}
                      onClick={() => setRole(value)}
                      className={`w-full p-5 rounded-2xl border-2 flex items-center gap-4 text-left transition-all ${
                        role === value
                          ? 'border-primary-600 bg-primary-50 shadow-sm'
                          : 'border-gray-200 hover:border-primary-300 hover:bg-gray-50'
                      }`}
                    >
                      <div className={`w-12 h-12 rounded-xl flex items-center justify-center shrink-0 ${iconBg}`}>
                        <Icon className="w-6 h-6" />
                      </div>
                      <div className="flex-1">
                        <div className="font-semibold text-gray-900">{title}</div>
                        <div className="text-sm text-gray-500 mt-0.5">{desc}</div>
                      </div>
                      <div
                        className={`w-5 h-5 rounded-full border-2 flex items-center justify-center shrink-0 transition-all ${
                          role === value ? 'border-primary-600 bg-primary-600' : 'border-gray-300'
                        }`}
                      >
                        {role === value && <Check className="w-3 h-3 text-white" />}
                      </div>
                    </button>
                  ))}
                </div>
                <button
                  onClick={() => role && setStep(1)}
                  disabled={!role}
                  className="btn-primary w-full mt-6"
                >
                  Continuer
                  <ArrowRight className="w-4 h-4" />
                </button>

                <GoogleAuthButton onSuccess={handleGoogleSuccess} />
              </div>
            )}

            {/* Étape 1 : informations personnelles */}
            {step === 1 && (
              <form onSubmit={handleAccountSubmit} className="animate-fade-up">
                <h1 className="text-2xl font-bold text-gray-900 mb-1">Vos informations</h1>
                <p className="text-gray-500 text-sm mb-6">
                  {isOpticien
                    ? 'Créez votre compte personnel. Vous configurerez votre boutique à l’étape suivante.'
                    : 'Renseignez vos informations pour créer votre compte.'}
                </p>

                <div className="space-y-4">
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="label">Prénom *</label>
                      <input value={form.first_name} onChange={set('first_name')} className="input-field" placeholder="Awa" required autoFocus />
                    </div>
                    <div>
                      <label className="label">Nom *</label>
                      <input value={form.last_name} onChange={set('last_name')} className="input-field" placeholder="Ouédraogo" required />
                    </div>
                  </div>
                  <div>
                    <label className="label">Nom d'utilisateur *</label>
                    <input value={form.username} onChange={set('username')} className="input-field" placeholder="awa.ouedraogo" required />
                  </div>
                  <div>
                    <label className="label">Email *</label>
                    <input
                      type="email"
                      value={form.email}
                      onChange={e => { set('email')(e); setEmailError(''); }}
                      className={`input-field ${emailError ? 'border-red-500 focus:ring-red-500' : ''}`}
                      placeholder="vous@example.com"
                      required
                    />
                    {emailError && <p className="mt-1 text-xs text-red-600">{emailError}</p>}
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="label">Téléphone</label>
                      <input type="tel" value={form.telephone} onChange={set('telephone')} className="input-field" placeholder="+226 70 00 00 00" />
                    </div>
                    <div>
                      <label className="label">Date de naissance</label>
                      <input type="date" value={form.date_naissance} onChange={set('date_naissance')} className="input-field" max={new Date().toISOString().split('T')[0]} />
                    </div>
                  </div>
                  <div>
                    <label className="label">Adresse</label>
                    <input value={form.adresse} onChange={set('adresse')} className="input-field" placeholder="Quartier, ville" />
                  </div>
                  <div>
                    <label className="label">Mot de passe *</label>
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
                      <button type="button" onClick={() => setShowPwd(!showPwd)} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                        {showPwd ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                      </button>
                    </div>
                    {form.password && (
                      <div className="mt-2 flex items-center gap-2">
                        <div className="flex-1 h-1.5 bg-gray-100 rounded-full overflow-hidden">
                          <div
                            className={`h-full rounded-full transition-all ${strength.color}`}
                            style={{ width: `${(strength.score / 5) * 100}%` }}
                          />
                        </div>
                        <span className="text-xs text-gray-500 w-12 text-right">{strength.label}</span>
                      </div>
                    )}
                  </div>
                </div>

                <div className="flex gap-3 mt-6">
                  <button type="button" onClick={() => setStep(0)} className="btn-secondary">
                    <ArrowLeft className="w-4 h-4" />
                    Retour
                  </button>
                  <button type="submit" disabled={loading} className="btn-primary flex-1">
                    {loading ? (
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />
                    ) : isOpticien ? (
                      <>Continuer <ArrowRight className="w-4 h-4" /></>
                    ) : (
                      <><UserPlus className="w-4 h-4" /> Créer mon compte</>
                    )}
                  </button>
                </div>
              </form>
            )}

            {/* Étape 2 : boutique (opticien uniquement) */}
            {step === 2 && (
              <form onSubmit={handleBoutiqueSubmit} className="animate-fade-up">
                <div className="flex items-center gap-3 mb-1">
                  <div className="w-10 h-10 bg-purple-100 rounded-xl flex items-center justify-center">
                    <Building2 className="w-5 h-5 text-purple-600" />
                  </div>
                  <h1 className="text-2xl font-bold text-gray-900">Votre boutique</h1>
                </div>
                <p className="text-gray-500 text-sm mb-6">
                  Ces informations seront visibles par vos clients. Vous pourrez les modifier à tout moment.
                </p>

                <div className="space-y-4">
                  <div>
                    <label className="label">Nom de la boutique *</label>
                    <input value={form.boutique_nom} onChange={set('boutique_nom')} className="input-field" placeholder="Optique Vision Plus" required autoFocus />
                  </div>
                  <div>
                    <label className="label">Adresse de la boutique *</label>
                    <input value={form.boutique_adresse} onChange={set('boutique_adresse')} className="input-field" placeholder="Secteur 10, Avenue Kwamé N'Krumah, Ouagadougou" required />
                  </div>
                  <div>
                    <label className="label">Téléphone de la boutique</label>
                    <input type="tel" value={form.boutique_telephone} onChange={set('boutique_telephone')} className="input-field" placeholder="+226 25 00 00 00" />
                  </div>
                  <div>
                    <label className="label">Description <span className="text-gray-400 font-normal">(optionnel)</span></label>
                    <textarea
                      value={form.boutique_description}
                      onChange={set('boutique_description')}
                      className="input-field resize-none"
                      rows={3}
                      placeholder="Présentez votre boutique en quelques mots : spécialités, marques, services..."
                    />
                  </div>
                </div>

                <div className="flex gap-3 mt-6">
                  <button type="button" onClick={() => setStep(1)} className="btn-secondary">
                    <ArrowLeft className="w-4 h-4" />
                    Retour
                  </button>
                  <button type="submit" disabled={loading} className="btn-primary flex-1">
                    {loading ? (
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />
                    ) : (
                      <><Store className="w-4 h-4" /> Créer ma boutique</>
                    )}
                  </button>
                </div>
              </form>
            )}

            <p className="text-center text-sm text-gray-500 mt-8">
              Déjà un compte ?{' '}
              <Link to="/login" className="text-primary-600 font-medium hover:underline">Se connecter</Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
