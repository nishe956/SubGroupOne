import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { Eye, LayoutDashboard, Glasses, ShoppingBag, Store, TrendingUp, LogOut, Menu, X } from 'lucide-react';
import { useState } from 'react';

export default function OpticienLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [menuOpen, setMenuOpen] = useState(false);

  const navItems = [
    { to: '/opticien', icon: LayoutDashboard, label: 'Tableau de bord', end: true },
    { to: '/opticien/montures', icon: Glasses, label: 'Mes montures' },
    { to: '/opticien/commandes', icon: ShoppingBag, label: 'Commandes' },
    { to: '/opticien/boutique', icon: Store, label: 'Ma boutique' },
    { to: '/opticien/marketing', icon: TrendingUp, label: 'Marketing' },
  ];

  const handleLogout = () => { logout(); navigate('/login'); };

  return (
    <div className="min-h-screen bg-gray-50 flex">
      {/* Sidebar desktop */}
      <aside className="w-64 bg-white border-r border-gray-200 hidden md:flex flex-col">
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-center gap-2">
            <Eye className="w-7 h-7 text-primary-600" />
            <div>
              <div className="font-bold text-gray-900">Lunette Pro</div>
              <div className="text-xs text-gray-500">Espace Opticien</div>
            </div>
          </div>
        </div>
        <nav className="flex-1 p-4 space-y-1">
          {navItems.map(({ to, icon: Icon, label, end }) => (
            <NavLink key={to} to={to} end={end} className={({ isActive }) =>
              `flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-colors ${isActive ? 'bg-primary-50 text-primary-700' : 'text-gray-600 hover:bg-gray-100'}`
            }>
              <Icon className="w-5 h-5" />{label}
            </NavLink>
          ))}
        </nav>
        <div className="p-4 border-t border-gray-200">
          <div className="flex items-center justify-between">
            <div>
              <div className="text-sm font-medium text-gray-900">{user?.first_name} {user?.last_name}</div>
              <div className="text-xs text-gray-500">{user?.username}</div>
            </div>
            <button onClick={handleLogout} className="text-gray-400 hover:text-red-500">
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        </div>
      </aside>

      {/* Mobile header */}
      <div className="md:hidden fixed top-0 left-0 right-0 z-50 bg-gradient-to-r from-[#0f172a] to-[#1e3a5f] h-14 flex items-center justify-between px-4">
        <div className="flex items-center gap-2">
          <Eye className="w-6 h-6 text-[#3b82f6]" />
          <span className="font-bold text-white">Lunette Pro</span>
        </div>
        <button onClick={() => setMenuOpen(!menuOpen)} className="text-white">
          {menuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
        </button>
      </div>
      {menuOpen && (
        <div className="md:hidden fixed inset-0 z-40 bg-black/50" onClick={() => setMenuOpen(false)}>
          <div className="bg-white w-64 h-full pt-14 flex flex-col" onClick={e => e.stopPropagation()}>
            <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
              {navItems.map(({ to, icon: Icon, label, end }) => (
                <NavLink key={to} to={to} end={end} onClick={() => setMenuOpen(false)} className={({ isActive }) =>
                  `flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-colors ${isActive ? 'bg-primary-50 text-primary-700' : 'text-gray-600 hover:bg-gray-100'}`
                }>
                  <Icon className="w-5 h-5" />{label}
                </NavLink>
              ))}
            </nav>
            <div className="p-4 border-t">
              <button onClick={handleLogout} className="flex items-center gap-2 text-red-500 text-sm">
                <LogOut className="w-4 h-4" /> Déconnexion
              </button>
            </div>
          </div>
        </div>
      )}

      <main className="flex-1 p-4 md:p-8 overflow-auto mt-14 md:mt-0">
        <Outlet />
      </main>
    </div>
  );
}
