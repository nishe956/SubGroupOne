import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { Eye, LayoutDashboard, Users, Building2, Shield, Settings, LogOut, Menu, X } from 'lucide-react';
import { useState } from 'react';

export default function AdminLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [menuOpen, setMenuOpen] = useState(false);

  const navItems = [
    { to: '/admin', icon: LayoutDashboard, label: 'Dashboard', end: true },
    { to: '/admin/utilisateurs', icon: Users, label: 'Utilisateurs' },
    { to: '/admin/opticiens', icon: Building2, label: 'Opticiens' },
    { to: '/admin/assurances', icon: Shield, label: 'Assurances' },
    { to: '/admin/maintenance', icon: Settings, label: 'Maintenance' },
  ];

  const handleLogout = () => { logout(); navigate('/login'); };

  return (
    <div className="min-h-screen bg-gray-50 flex">
      <aside className="w-64 bg-gray-900 text-white hidden md:flex flex-col">
        <div className="p-6 border-b border-gray-700">
          <div className="flex items-center gap-2">
            <Eye className="w-7 h-7 text-primary-400" />
            <div>
              <div className="font-bold">Lunette Pro</div>
              <div className="text-xs text-gray-400">Administration</div>
            </div>
          </div>
        </div>
        <nav className="flex-1 p-4 space-y-1">
          {navItems.map(({ to, icon: Icon, label, end }) => (
            <NavLink key={to} to={to} end={end} className={({ isActive }) =>
              `flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-colors ${isActive ? 'bg-primary-600 text-white' : 'text-gray-400 hover:bg-gray-800 hover:text-white'}`
            }>
              <Icon className="w-5 h-5" />{label}
            </NavLink>
          ))}
        </nav>
        <div className="p-4 border-t border-gray-700">
          <div className="flex items-center justify-between">
            <div className="text-sm text-gray-400">{user?.first_name} {user?.last_name}</div>
            <button onClick={handleLogout} className="text-gray-400 hover:text-red-400">
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        </div>
      </aside>

      {/* Mobile header */}
      <div className="md:hidden fixed top-0 left-0 right-0 z-50 bg-gray-900 h-14 flex items-center justify-between px-4">
        <div className="flex items-center gap-2">
          <Eye className="w-6 h-6 text-primary-400" />
          <span className="font-bold text-white">Admin</span>
        </div>
        <button onClick={() => setMenuOpen(!menuOpen)} className="text-white">
          {menuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
        </button>
      </div>
      {menuOpen && (
        <div className="md:hidden fixed inset-0 z-40 bg-black/50" onClick={() => setMenuOpen(false)}>
          <div className="bg-gray-900 w-64 h-full pt-14 flex flex-col" onClick={e => e.stopPropagation()}>
            <nav className="flex-1 p-4 space-y-1">
              {navItems.map(({ to, icon: Icon, label, end }) => (
                <NavLink key={to} to={to} end={end} onClick={() => setMenuOpen(false)} className={({ isActive }) =>
                  `flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-colors ${isActive ? 'bg-primary-600 text-white' : 'text-gray-400 hover:bg-gray-800 hover:text-white'}`
                }>
                  <Icon className="w-5 h-5" />{label}
                </NavLink>
              ))}
            </nav>
            <div className="p-4 border-t border-gray-700">
              <button onClick={handleLogout} className="flex items-center gap-2 text-red-400 text-sm">
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
