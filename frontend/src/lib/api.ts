import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || '/api';

/**
 * Le jeton d'accès est conservé en MÉMOIRE uniquement.
 *
 * Il était auparavant stocké dans `localStorage`, avec le jeton de
 * rafraîchissement : toute XSS, toute dépendance npm compromise ou toute
 * extension de navigateur pouvait les lire et prendre le contrôle du compte
 * pour plusieurs jours. Le jeton de rafraîchissement vit désormais dans un
 * cookie httpOnly posé par le serveur, inaccessible à JavaScript.
 */
let accessToken: string | null = null;

export const setAccessToken = (token: string | null) => {
  accessToken = token;
};
export const getAccessToken = () => accessToken;

const api = axios.create({
  baseURL: API_URL,
  headers: { 'Content-Type': 'application/json' },
  // Indispensable pour que le navigateur transmette le cookie de
  // rafraîchissement au domaine de l'API (le backend autorise explicitement
  // l'origine du frontend via CORS_ALLOWED_ORIGINS).
  withCredentials: true,
});

api.interceptors.request.use((config) => {
  if (accessToken) config.headers.Authorization = `Bearer ${accessToken}`;
  return config;
});

/** Appelle l'endpoint de rafraîchissement ; le cookie fait office d'identifiant. */
export async function rafraichirSession(): Promise<string | null> {
  try {
    const { data } = await axios.post(
      `${API_URL}/users/token/refresh/`,
      {},
      { withCredentials: true },
    );
    accessToken = data.access;
    return accessToken;
  } catch {
    accessToken = null;
    return null;
  }
}

// Un seul rafraîchissement à la fois : sans cette file d'attente, plusieurs
// requêtes en 401 simultanées déclencheraient autant de rotations concurrentes
// du jeton, dont une seule resterait valide.
let rafraichissementEnCours: Promise<string | null> | null = null;

api.interceptors.response.use(
  (res) => res,
  async (error) => {
    const original = error.config;
    const estRefresh = original?.url?.includes('/users/token/refresh/');

    if (error.response?.status === 401 && !original?._retry && !estRefresh) {
      original._retry = true;

      rafraichissementEnCours = rafraichissementEnCours ?? rafraichirSession();
      const nouveau = await rafraichissementEnCours;
      rafraichissementEnCours = null;

      if (nouveau) {
        original.headers.Authorization = `Bearer ${nouveau}`;
        return api(original);
      }

      // Session réellement terminée : on ne redirige que si l'utilisateur n'est
      // pas déjà sur une page publique, pour ne pas interrompre la navigation.
      const cheminsPublics = ['/login', '/register', '/mot-de-passe-oublie', '/reinitialiser-mot-de-passe', '/'];
      if (!cheminsPublics.includes(window.location.pathname)) {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  },
);

export const MEDIA_BASE = import.meta.env.VITE_MEDIA_BASE || '';

export function mediaUrl(path: string | null | undefined): string {
  if (!path) return '';
  if (path.startsWith('http')) return path;
  if (!MEDIA_BASE) return path;
  return `${MEDIA_BASE}${path}`;
}

export function formatCFA(prix: number | string): string {
  const n = Number(prix);
  if (isNaN(n)) return '0 F CFA';
  return n.toLocaleString('fr-FR').replace(/\s/g, '.') + ' F CFA';
}

/**
 * Extrait un message lisible d'une erreur d'API.
 *
 * DRF renvoie trois formes selon le cas : `{detail: "..."}` pour une erreur
 * globale, `["..."]` pour une ValidationError sur un message simple, et
 * `{champ: ["..."]}` pour une erreur de champ. Ne lire que `.detail` faisait
 * disparaître les deux dernières — l'utilisateur voyait un message générique
 * au lieu de la vraie raison du refus.
 */
export function messageErreur(err: unknown, defaut = 'Une erreur est survenue'): string {
  const data = (err as { response?: { data?: unknown } })?.response?.data;
  if (!data) return defaut;
  if (typeof data === 'string') return data;
  if (Array.isArray(data)) return String(data[0] ?? defaut);

  const objet = data as Record<string, unknown>;
  if (typeof objet.detail === 'string') return objet.detail;

  const premier = Object.values(objet)[0];
  if (Array.isArray(premier)) return String(premier[0] ?? defaut);
  if (typeof premier === 'string') return premier;
  return defaut;
}

/** Déballe une réponse paginée DRF (`{count, results}`) ou une liste brute. */
export function listeDepuis<T>(data: unknown): T[] {
  if (Array.isArray(data)) return data as T[];
  const paginee = data as { results?: T[] } | null;
  return paginee?.results ?? [];
}

export default api;
