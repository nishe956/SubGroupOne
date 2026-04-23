import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { Eye, ShoppingBag, FileText, User, LogOut, Home, Users, BookOpen } from 'lucide-react';

export default function ClientLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => { logout(); navigate('/login'); };

  const navItems = [
    { to: '/catalogue', icon: Home, label: 'Catalogue' },
    { to: '/ordonnances', icon: FileText, label: 'Ordonnances' },
    { to: '/commandes', icon: ShoppingBag, label: 'Commandes' },
    { to: '/publications', icon: BookOpen, label: 'Blog' },
    { to: '/famille', icon: Users, label: 'Famille' },
    { to: '/profil', icon: User, label: 'Profil' },
  ];

  return (
    <div className="min-h-screen bg-gray-50 pb-16 md:pb-0">
      {/* Desktop / Mobile header */}
      <header className="sticky top-0 z-50 bg-gradient-to-r from-[#0f172a] to-[#1e3a5f] shadow-lg md:bg-white md:bg-none md:border-b md:border-gray-200 md:shadow-none" style={{}}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-2">
              <Eye className="w-7 h-7 text-[#3b82f6] md:text-primary-600" />
              <span className="font-bold text-xl text-white md:text-gray-900">Lunette Pro</span>
            </div>
            <nav className="hidden md:flex items-center gap-1">
              {navItems.map(({ to, icon: Icon, label }) => (
                <NavLink key={to} to={to} className={({ isActive }) =>
                  `flex items-center gap-2 px-3 py-2 rounded-xl text-sm font-medium transition-colors ${isActive ? 'bg-primary-50 text-primary-700' : 'text-gray-600 hover:bg-gray-100'}`
                }>
                  <Icon className="w-4 h-4" />{label}
                </NavLink>
              ))}
            </nav>
            <div className="flex items-center gap-3">
              <span className="text-sm text-white md:text-gray-700 hidden sm:block">{user?.first_name || user?.username}</span>
              <button onClick={handleLogout} className="flex items-center gap-1 text-white md:text-gray-500 hover:text-red-400 md:hover:text-red-500 transition-colors">
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <Outlet />
      </main>

      {/* Bottom nav mobile */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-gradient-to-r from-[#0f172a] to-[#1e3a5f] border-t border-blue-800 z-50">
        <div className="flex justify-around py-2">
          {navItems.map(({ to, icon: Icon, label }) => (
            <NavLink key={to} to={to} className={({ isActive }) =>
              `flex flex-col items-center gap-0.5 px-2 py-1 text-xs ${isActive ? 'text-[#3b82f6]' : 'text-blue-300'}`
            }>
              <Icon className="w-5 h-5" />
              <span>{label}</span>
            </NavLink>
          ))}
        </div>
      </nav>
    </div>
  );
}
