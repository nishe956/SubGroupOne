import { Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { AuthProvider, useAuth } from '@/contexts/AuthContext';
import { ReactNode, useEffect } from 'react';
import { enregistrerVisite } from '@/lib/tracking';

// Auth pages
import LoginPage from '@/pages/auth/LoginPage';
import RegisterPage from '@/pages/auth/RegisterPage';
import ForgotPasswordPage from '@/pages/auth/ForgotPasswordPage';
import ResetPasswordPage from '@/pages/auth/ResetPasswordPage';

// Landing
import LandingPage from '@/pages/LandingPage';

// Client pages
import ClientLayout from '@/layouts/ClientLayout';
import CatalogPage from '@/pages/client/CatalogPage';
import MontureDetailPage from '@/pages/client/MontureDetailPage';
import VirtualTryOnPage from '@/pages/client/VirtualTryOnPage';
import OrdonnancePage from '@/pages/client/OrdonnancePage';
import ClientCommandesPage from '@/pages/client/CommandesPage';
import ProfilePage from '@/pages/client/ProfilePage';
import PublicationsPage from '@/pages/client/PublicationsPage';
import FamillePage from '@/pages/client/FamillePage';
// Opticien pages
import OpticienLayout from '@/layouts/OpticienLayout';
import OpticienDashboard from '@/pages/opticien/DashboardPage';
import OpticienMontures from '@/pages/opticien/MonturesPage';
import OpticienCommandes from '@/pages/opticien/CommandesPage';
import BoutiquePage from '@/pages/opticien/BoutiquePage';
import MarketingPage from '@/pages/opticien/MarketingPage';

// Admin pages
import AdminLayout from '@/layouts/AdminLayout';
import AdminDashboard from '@/pages/admin/DashboardPage';
import AdminUsers from '@/pages/admin/UsersPage';
import AdminOpticiens from '@/pages/admin/OpticiensPage';
import AdminAssurances from '@/pages/admin/AssurancesPage';
import AdminMaintenance from '@/pages/admin/MaintenancePage';

// Page de statistiques partagée : l'admin voit le réseau, l'opticien sa boutique.
import StatistiquesPage from '@/pages/StatistiquesPage';

/** Enregistre une page vue à chaque changement de route (hors back-office). */
const SuiviVisites = () => {
  const { pathname } = useLocation();
  useEffect(() => { enregistrerVisite(pathname); }, [pathname]);
  return null;
};

const ProtectedRoute = ({ children, roles }: { children: ReactNode; roles?: string[] }) => {
  const { user, isLoading } = useAuth();
  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600" />
      </div>
    );
  }
  if (!user) return <Navigate to="/login" replace />;
  if (roles && !roles.includes(user.role)) {
    return <Navigate to={user.role === 'admin' ? '/admin' : user.role === 'opticien' ? '/opticien' : '/catalogue'} replace />;
  }
  return <>{children}</>;
};

const AppRoutes = () => {
  const { user } = useAuth();

  const home = user
    ? user.role === 'admin' ? '/admin'
    : user.role === 'opticien' ? '/opticien'
    : '/catalogue'
    : null;

  return (
    <>
    <SuiviVisites />
    <Routes>
      <Route path="/" element={home ? <Navigate to={home} replace /> : <LandingPage />} />
      <Route path="/login" element={user ? <Navigate to={home!} replace /> : <LoginPage />} />
      <Route path="/register" element={user ? <Navigate to={home!} replace /> : <RegisterPage />} />
      <Route path="/mot-de-passe-oublie" element={user ? <Navigate to={home!} replace /> : <ForgotPasswordPage />} />
      <Route path="/reinitialiser-mot-de-passe" element={user ? <Navigate to={home!} replace /> : <ResetPasswordPage />} />

      {/* Client routes */}
      <Route path="/" element={<ProtectedRoute roles={['client']}><ClientLayout /></ProtectedRoute>}>
        <Route path="catalogue" element={<CatalogPage />} />
        <Route path="montures/:id" element={<MontureDetailPage />} />
        <Route path="essai-virtuel/:id" element={<VirtualTryOnPage />} />
        <Route path="ordonnances" element={<OrdonnancePage />} />
        <Route path="commandes" element={<ClientCommandesPage />} />
        <Route path="profil" element={<ProfilePage />} />
        <Route path="publications" element={<PublicationsPage />} />
        <Route path="famille" element={<FamillePage />} />
      </Route>

      {/* Opticien routes */}
      <Route path="/opticien" element={<ProtectedRoute roles={['opticien']}><OpticienLayout /></ProtectedRoute>}>
        <Route index element={<OpticienDashboard />} />
        <Route path="statistiques" element={<StatistiquesPage />} />
        <Route path="montures" element={<OpticienMontures />} />
        <Route path="commandes" element={<OpticienCommandes />} />
        <Route path="boutique" element={<BoutiquePage />} />
        <Route path="marketing" element={<MarketingPage />} />
      </Route>

      {/* Admin routes */}
      <Route path="/admin" element={<ProtectedRoute roles={['admin']}><AdminLayout /></ProtectedRoute>}>
        <Route index element={<AdminDashboard />} />
        <Route path="statistiques" element={<StatistiquesPage />} />
        <Route path="utilisateurs" element={<AdminUsers />} />
        <Route path="opticiens" element={<AdminOpticiens />} />
        <Route path="assurances" element={<AdminAssurances />} />
        <Route path="maintenance" element={<AdminMaintenance />} />
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
    </>
  );
};

export default function App() {
  return (
    <AuthProvider>
      <AppRoutes />
    </AuthProvider>
  );
}
