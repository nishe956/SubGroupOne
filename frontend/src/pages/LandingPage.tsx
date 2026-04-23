import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Eye, Camera, FileText, Shield, Users, ArrowRight, ShoppingBag, Star, X } from 'lucide-react';
import api, { mediaUrl, formatCFA } from '@/lib/api';

/* ── Modal invitation connexion ─────────────────────────────── */
function AuthModal({ onClose }: { onClose: () => void }) {
  const navigate = useNavigate();
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm px-4"
      onClick={onClose}>
      <div className="bg-white rounded-3xl p-8 max-w-sm w-full shadow-2xl text-center"
        onClick={e => e.stopPropagation()}>
        <button onClick={onClose} className="absolute top-4 right-4 text-gray-400 hover:text-gray-600">
          <X className="w-5 h-5" />
        </button>
        <div className="w-16 h-16 bg-primary-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <ShoppingBag className="w-8 h-8 text-primary-600" />
        </div>
        <h2 className="text-xl font-bold text-gray-900 mb-2">Créez votre compte</h2>
        <p className="text-gray-500 text-sm mb-6">
          Pour commander, gérer vos ordonnances et profiter de tous nos services, créez un compte gratuitement.
        </p>
        <div className="flex flex-col gap-3">
          <button onClick={() => navigate('/register')}
            className="btn-primary w-full py-3 text-base">
            Créer un compte gratuit
          </button>
          <button onClick={() => navigate('/login')}
            className="btn-secondary w-full py-3 text-base">
            J'ai déjà un compte
          </button>
        </div>
      </div>
    </div>
  );
}

/* ── Hero Carousel ───────────────────────────────────────────── */
const SLIDES = [
  {
    title: 'Trouvez vos lunettes parfaites',
    subtitle: 'Des centaines de montures disponibles en ligne, livrées chez vous.',
    bg: 'from-primary-600 to-primary-800',
  },
  {
    title: 'Essai virtuel en temps réel',
    subtitle: 'Essayez les montures grâce à votre caméra avant de commander.',
    bg: 'from-indigo-600 to-purple-700',
  },
  {
    title: 'Gérez vos ordonnances',
    subtitle: 'Uploadez vos ordonnances et laissez notre IA extraire les données.',
    bg: 'from-emerald-600 to-teal-700',
  },
];

function HeroCarousel({ onCTA }: { onCTA: () => void }) {
  const [current, setCurrent] = useState(0);

  useEffect(() => {
    const t = setInterval(() => setCurrent(c => (c + 1) % SLIDES.length), 4000);
    return () => clearInterval(t);
  }, []);

  return (
    <div className="relative overflow-hidden h-[480px] md:h-[560px]">
      {SLIDES.map((slide, i) => (
        <div
          key={i}
          className={`absolute inset-0 bg-gradient-to-br ${slide.bg} flex items-center justify-center transition-opacity duration-1000 ${i === current ? 'opacity-100' : 'opacity-0'}`}
        >
          {/* Cercles décoratifs animés */}
          <div className="absolute top-10 left-10 w-64 h-64 bg-white/5 rounded-full animate-pulse" />
          <div className="absolute bottom-10 right-10 w-96 h-96 bg-white/5 rounded-full animate-pulse delay-700" />
          <div className="absolute top-1/2 left-1/4 w-32 h-32 bg-white/10 rounded-full" />

          <div className="relative z-10 text-center px-6 max-w-3xl">
            <div className="inline-flex items-center gap-2 bg-white/20 backdrop-blur-sm text-white rounded-full px-4 py-2 text-sm font-medium mb-6">
              <Star className="w-4 h-4" /> Plateforme optique complète
            </div>
            <h1 className="text-4xl md:text-6xl font-bold text-white leading-tight mb-4 drop-shadow">
              {slide.title}
            </h1>
            <p className="text-xl text-white/80 mb-8">{slide.subtitle}</p>
            <button
              onClick={onCTA}
              className="inline-flex items-center gap-2 bg-white text-primary-700 font-semibold px-8 py-4 rounded-2xl text-lg hover:bg-primary-50 transition-all shadow-lg hover:shadow-xl hover:-translate-y-0.5"
            >
              Commencer gratuitement <ArrowRight className="w-5 h-5" />
            </button>
          </div>
        </div>
      ))}

      {/* Indicateurs */}
      <div className="absolute bottom-6 left-1/2 -translate-x-1/2 flex gap-2 z-20">
        {SLIDES.map((_, i) => (
          <button
            key={i}
            onClick={() => setCurrent(i)}
            className={`rounded-full transition-all ${i === current ? 'w-8 h-2 bg-white' : 'w-2 h-2 bg-white/50'}`}
          />
        ))}
      </div>
    </div>
  );
}

/* ── Carte monture publique ─────────────────────────────────── */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function MontureCard({ m, onAction }: { m: any; onAction: () => void }) {
  const imgSrc = m.image ? mediaUrl(m.image) : m.image_principale ? mediaUrl(m.image_principale) : null;

  return (
    <div className="bg-white rounded-2xl border border-gray-100 shadow-sm hover:shadow-lg transition-all duration-300 overflow-hidden group hover:-translate-y-1">
      <div className="relative bg-gray-100 h-48 overflow-hidden">
        {imgSrc ? (
          <img src={imgSrc} alt={m.nom} loading="lazy" className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <Eye className="w-16 h-16 text-gray-300" />
          </div>
        )}
        {m.stock === 0 && (
          <span className="absolute top-2 right-2 bg-red-100 text-red-700 text-xs font-medium px-2 py-1 rounded-full">Rupture</span>
        )}
        {m.stock > 0 && m.stock <= 3 && (
          <span className="absolute top-2 right-2 bg-orange-100 text-orange-700 text-xs font-medium px-2 py-1 rounded-full">Plus que {m.stock}</span>
        )}
      </div>
      <div className="p-4">
        <div className="text-xs text-gray-400 font-medium mb-1">{m.marque}</div>
        <h3 className="font-semibold text-gray-900 truncate mb-1">{m.nom}</h3>
        <div className="flex gap-1 mb-3">
          <span className="bg-gray-100 text-gray-600 text-xs px-2 py-0.5 rounded-full">{m.forme}</span>
          <span className="bg-gray-100 text-gray-600 text-xs px-2 py-0.5 rounded-full">{m.couleur}</span>
        </div>
        <div className="flex items-center justify-between">
          <span className="font-bold text-gray-900">{formatCFA(m.prix)}</span>
          <button
            onClick={onAction}
            className="flex items-center gap-1.5 bg-primary-600 hover:bg-primary-700 text-white text-sm px-3 py-1.5 rounded-xl transition-colors"
          >
            <ShoppingBag className="w-3.5 h-3.5" /> Commander
          </button>
        </div>
      </div>
    </div>
  );
}

/* ── Page principale ────────────────────────────────────────── */
export default function LandingPage() {
  const navigate = useNavigate();
  const [showModal, setShowModal] = useState(false);

  const { data } = useQuery({
    queryKey: ['public-montures'],
    queryFn: () => api.get('/montures/', { params: { disponible: 'true' } }).then(r => r.data),
  });

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const montures: any[] = Array.isArray(data) ? data : (data?.results || []);

  const features = [
    { icon: Camera, title: 'Essai virtuel', desc: 'Essayez des montures en temps réel avec votre caméra.', color: 'bg-blue-100 text-blue-600' },
    { icon: FileText, title: 'Ordonnances', desc: 'Uploadez vos ordonnances, notre IA extrait les données automatiquement.', color: 'bg-purple-100 text-purple-600' },
    { icon: Shield, title: 'Assurance', desc: 'Simulez votre remboursement assurance en un clic.', color: 'bg-green-100 text-green-600' },
    { icon: Users, title: 'Groupe famille', desc: 'Profitez de rabais spéciaux avec votre groupe famille.', color: 'bg-orange-100 text-orange-600' },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {showModal && <AuthModal onClose={() => setShowModal(false)} />}

      {/* Header */}
      <header className="sticky top-0 z-40 bg-white/80 backdrop-blur-md border-b border-gray-100">
        <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-primary-600 rounded-xl flex items-center justify-center">
              <Eye className="w-5 h-5 text-white" />
            </div>
            <span className="font-bold text-xl text-gray-900">Lunette Pro</span>
          </div>
          <div className="flex items-center gap-3">
            <button onClick={() => navigate('/login')}
              className="text-sm text-gray-600 hover:text-gray-900 font-medium px-4 py-2 rounded-xl hover:bg-gray-100 transition-colors">
              Se connecter
            </button>
            <button onClick={() => navigate('/register')}
              className="btn-primary text-sm px-5 py-2">
              Créer un compte
            </button>
          </div>
        </div>
      </header>

      {/* Hero Carousel */}
      <HeroCarousel onCTA={() => navigate('/register')} />

      {/* Features */}
      <section className="py-16 bg-white">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-10">
            <h2 className="text-3xl font-bold text-gray-900 mb-3">Tout ce dont vous avez besoin</h2>
            <p className="text-gray-500">Une plateforme complète pour gérer vos lunettes</p>
          </div>
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            {features.map(({ icon: Icon, title, desc, color }) => (
              <div key={title}
                className="bg-white border border-gray-100 rounded-2xl p-6 hover:shadow-md transition-all hover:-translate-y-0.5 cursor-default">
                <div className={`w-12 h-12 ${color} rounded-2xl flex items-center justify-center mb-4`}>
                  <Icon className="w-6 h-6" />
                </div>
                <h3 className="font-semibold text-gray-900 mb-1">{title}</h3>
                <p className="text-gray-500 text-sm leading-relaxed">{desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Catalogue public */}
      <section className="py-16">
        <div className="max-w-7xl mx-auto px-6">
          <div className="flex items-center justify-between mb-8">
            <div>
              <h2 className="text-3xl font-bold text-gray-900 mb-1">Nos montures</h2>
              <p className="text-gray-500">{montures.length} monture{montures.length !== 1 ? 's' : ''} disponible{montures.length !== 1 ? 's' : ''}</p>
            </div>
            <button onClick={() => setShowModal(true)}
              className="btn-primary flex items-center gap-2 hidden md:flex">
              Voir tout le catalogue <ArrowRight className="w-4 h-4" />
            </button>
          </div>

          {montures.length === 0 ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
              {[...Array(8)].map((_, i) => (
                <div key={i} className="h-72 bg-gray-200 animate-pulse rounded-2xl" />
              ))}
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {montures.slice(0, 8).map(m => (
                <MontureCard key={m.id} m={m} onAction={() => setShowModal(true)} />
              ))}
            </div>
          )}

          <div className="text-center mt-10">
            <button onClick={() => setShowModal(true)}
              className="btn-primary px-8 py-3 text-base flex items-center gap-2 mx-auto">
              Accéder à tout le catalogue <ArrowRight className="w-5 h-5" />
            </button>
          </div>
        </div>
      </section>

      {/* CTA final */}
      <section className="py-20 bg-gradient-to-br from-primary-600 to-primary-800 mx-6 mb-12 rounded-3xl">
        <div className="text-center px-6 max-w-2xl mx-auto">
          <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">Prêt à commander ?</h2>
          <p className="text-white/80 text-lg mb-8">Créez votre compte gratuitement et profitez de tous nos services.</p>
          <button onClick={() => navigate('/register')}
            className="inline-flex items-center gap-2 bg-white text-primary-700 font-semibold px-8 py-4 rounded-2xl text-lg hover:bg-primary-50 transition-all shadow-lg hover:shadow-xl">
            Commencer maintenant <ArrowRight className="w-5 h-5" />
          </button>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-gray-100 py-8 text-center text-sm text-gray-400">
        © 2025 Lunette Pro. Tous droits réservés.
      </footer>
    </div>
  );
}
