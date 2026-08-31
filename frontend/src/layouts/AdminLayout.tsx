import { useEffect, useState } from 'react';
import { Outlet, NavLink, useNavigate, useLocation } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
  Glasses, LayoutDashboard, ChartColumn, UsersRound, Stethoscope, ShieldCheck,
  Wrench, Search, Bell, LogOut, Menu, X, ChevronDown, LucideIcon,
} from 'lucide-react';
import api, { listeDepuis } from '@/lib/api';
import { useAuth } from '@/contexts/AuthContext';
import { Avatar } from '@/components/admin';

interface ItemNav { to: string; label: string; icone: LucideIcon; end?: boolean }

const NAV: ItemNav[] = [
  { to: '/admin',               label: 'Dashboard',    icone: LayoutDashboard, end: true },
  { to: '/admin/statistiques',  label: 'Statistiques', icone: ChartColumn },
  { to: '/admin/utilisateurs',  label: 'Utilisateurs', icone: UsersRound },
  { to: '/admin/opticiens',     label: 'Opticiens',    icone: Stethoscope },
  { to: '/admin/assurances',    label: 'Assurances',   icone: ShieldCheck },
  { to: '/admin/maintenance',   label: 'Maintenance',  icone: Wrench },
];

/** Lien de navigation : l'état actif est porté par un aplat, pas par la seule couleur du texte. */
function LienNav({ item, onClick }: { item: ItemNav; onClick?: () => void }) {
  const Icone = item.icone;
  return (
    <NavLink
      to={item.to}
      end={item.end}
      onClick={onClick}
      className={({ isActive }) =>
        `flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm transition-colors ${
          isActive
            ? 'bg-accent-50 text-accent-600 font-semibold'
            : 'text-gray-500 font-medium hover:bg-gray-50 hover:text-gray-900'
        }`
      }
    >
      <Icone className="w-[18px] h-[18px] flex-shrink-0" strokeWidth={1.75} />
      {item.label}
    </NavLink>
  );
}

function Marque() {
  return (
    <div className="flex items-center gap-2.5">
      <span className="w-9 h-9 rounded-xl bg-accent-500 flex items-center justify-center flex-shrink-0">
        <Glasses className="w-5 h-5 text-white" strokeWidth={2} />
      </span>
      <span className="leading-tight">
        <span className="block font-bold text-gray-900">Lunette Pro</span>
        <span className="block text-[11px] text-gray-400">Administration</span>
      </span>
    </div>
  );
}

export default function AdminLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [menuMobile, setMenuMobile] = useState(false);
  const [menuCompte, setMenuCompte] = useState(false);
  const [recherche, setRecherche] = useState('');

  // Le tiroir mobile reste ouvert par-dessus la page suivante si on ne le ferme
  // pas explicitement au changement d'écran.
  useEffect(() => { setMenuMobile(false); setMenuCompte(false); }, [location.pathname]);

  // Compteur de la cloche : les demandes d'opticiens réellement en attente.
  const { data: enAttente } = useQuery({
    queryKey: ['opticiens-en-attente'],
    queryFn: () => api.get('/users/opticiens/en-attente/').then(r => listeDepuis(r.data)),
  });
  const nbEnAttente = enAttente?.length ?? 0;

  const nomComplet = `${user?.first_name ?? ''} ${user?.last_name ?? ''}`.trim() || user?.username || 'Administrateur';
  const deconnexion = () => { logout(); navigate('/login'); };

  const lancerRecherche = (e: React.FormEvent) => {
    e.preventDefault();
    if (!recherche.trim()) return;
    navigate(`/admin/utilisateurs?q=${encodeURIComponent(recherche.trim())}`);
  };

  const pied = (
    <div className="p-3 border-t border-gray-100">
      <div className="relative">
        {menuCompte && (
          <div className="absolute bottom-full left-0 right-0 mb-2 rounded-xl border border-gray-100 bg-white shadow-card p-1">
            <button
              onClick={deconnexion}
              className="w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium text-red-600 hover:bg-red-50 transition-colors"
            >
              <LogOut className="w-4 h-4" /> Déconnexion
            </button>
          </div>
        )}
        <button
          onClick={() => setMenuCompte(o => !o)}
          aria-expanded={menuCompte}
          className="w-full flex items-center gap-3 p-2 rounded-xl hover:bg-gray-50 transition-colors text-left"
        >
          <Avatar nom={nomComplet} taille="md" />
          <span className="flex-1 min-w-0 leading-tight">
            <span className="block text-sm font-semibold text-gray-900 truncate">{nomComplet}</span>
            <span className="block text-xs text-gray-400">Administrateur</span>
          </span>
          <ChevronDown className={`w-4 h-4 text-gray-400 transition-transform ${menuCompte ? 'rotate-180' : ''}`} />
        </button>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Sidebar fixe (écrans larges) */}
      <aside className="hidden lg:flex fixed inset-y-0 left-0 w-64 bg-white border-r border-gray-100 flex-col z-30">
        <div className="h-16 flex items-center px-5 border-b border-gray-100"><Marque /></div>
        <nav className="flex-1 p-3 space-y-1 overflow-y-auto">
          {NAV.map(item => <LienNav key={item.to} item={item} />)}
        </nav>
        {pied}
      </aside>

      {/* Tiroir mobile */}
      {menuMobile && (
        <div className="lg:hidden fixed inset-0 z-40 bg-gray-900/40" onClick={() => setMenuMobile(false)}>
          <div className="w-64 h-full bg-white flex flex-col" onClick={e => e.stopPropagation()}>
            <div className="h-16 flex items-center justify-between px-5 border-b border-gray-100">
              <Marque />
              <button onClick={() => setMenuMobile(false)} aria-label="Fermer le menu" className="text-gray-400 hover:text-gray-900">
                <X className="w-5 h-5" />
              </button>
            </div>
            <nav className="flex-1 p-3 space-y-1 overflow-y-auto">
              {NAV.map(item => <LienNav key={item.to} item={item} onClick={() => setMenuMobile(false)} />)}
            </nav>
            {pied}
          </div>
        </div>
      )}

      <div className="lg:pl-64">
        <header className="sticky top-0 z-20 h-16 bg-white/85 backdrop-blur border-b border-gray-100 flex items-center gap-3 px-4 md:px-8">
          <button
            onClick={() => setMenuMobile(true)}
            aria-label="Ouvrir le menu"
            className="lg:hidden p-2 -ml-2 rounded-lg text-gray-500 hover:bg-gray-100"
          >
            <Menu className="w-5 h-5" />
          </button>

          <form onSubmit={lancerRecherche} className="relative flex-1 max-w-sm" role="search">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
            <input
              value={recherche}
              onChange={e => setRecherche(e.target.value)}
              placeholder="Rechercher un utilisateur..."
              aria-label="Rechercher un utilisateur"
              className="champ-admin pl-9 py-2"
            />
          </form>

          <div className="ml-auto">
            <button
              onClick={() => navigate('/admin/opticiens')}
              aria-label={nbEnAttente > 0 ? `${nbEnAttente} demande(s) d'opticien en attente` : 'Aucune demande en attente'}
              className="relative p-2 rounded-lg text-gray-500 hover:bg-gray-100 transition-colors"
            >
              <Bell className="w-5 h-5" strokeWidth={1.75} />
              {nbEnAttente > 0 && (
                <span className="absolute -top-0.5 -right-0.5 min-w-[18px] h-[18px] px-1 rounded-full bg-accent-500 text-white text-[10px] font-bold flex items-center justify-center">
                  {nbEnAttente > 9 ? '9+' : nbEnAttente}
                </span>
              )}
            </button>
          </div>
        </header>

        <main className="p-4 md:p-8">
          <div className="max-w-[1400px] mx-auto">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
}
