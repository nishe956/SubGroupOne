import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { User } from '@/types';
import api, { setAccessToken, rafraichirSession } from '@/lib/api';
import { queryClient } from '@/main';

interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  login: (username: string, password: string) => Promise<void>;
  loginWithGoogle: (credential: string) => Promise<void>;
  logout: () => void;
  updateUser: (user: User) => void;
}

const AuthContext = createContext<AuthContextType | null>(null);

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  /**
   * Au chargement, la session est reconstruite à partir du cookie httpOnly de
   * rafraîchissement — plus rien n'est lu dans localStorage. C'est ce qui permet
   * de garder le jeton d'accès hors de portée de JavaScript tout en conservant
   * la session après un rechargement de page.
   */
  useEffect(() => {
    let annule = false;

    (async () => {
      // Nettoyage unique des jetons laissés par l'ancienne version : les laisser
      // dans localStorage maintiendrait la surface d'attaque qu'on vient de fermer.
      localStorage.removeItem('access_token');
      localStorage.removeItem('refresh_token');
      localStorage.removeItem('user');

      const token = await rafraichirSession();
      if (annule) return;

      if (token) {
        try {
          const { data } = await api.get('/users/profil/');
          if (!annule) setUser(data);
        } catch {
          if (!annule) setAccessToken(null);
        }
      }
      if (!annule) setIsLoading(false);
    })();

    return () => { annule = true; };
  }, []);

  const login = async (username: string, password: string) => {
    const res = await api.post('/users/login/', { username, password });
    // La réponse ne contient plus le refresh token : il est posé dans un cookie
    // httpOnly par le serveur.
    setAccessToken(res.data.access);
    setUser(res.data.user);
  };

  const loginWithGoogle = async (credential: string) => {
    const res = await api.post('/users/google-login/', { credential });
    setAccessToken(res.data.access);
    setUser(res.data.user);
  };

  const logout = async () => {
    try {
      // Le serveur lit le cookie pour blacklister le refresh token.
      await api.post('/users/logout/', {});
    } catch {
      // continuer même si le serveur est indisponible
    }
    setUser(null);
    setAccessToken(null);
    queryClient.clear();
  };

  const updateUser = (u: User) => setUser(u);

  return (
    <AuthContext.Provider value={{ user, isLoading, login, loginWithGoogle, logout, updateUser }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
};
