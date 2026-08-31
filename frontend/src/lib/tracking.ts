import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || '/api';

/**
 * Instance dédiée au suivi, volontairement SANS l'intercepteur d'authentification
 * de `api.ts` : un jeton expiré ferait échouer l'appel en 401 (DRF authentifie
 * avant d'évaluer les permissions, même sur une vue AllowAny), et l'intercepteur
 * déconnecterait alors l'utilisateur en pleine navigation. Le suivi n'a besoin
 * d'aucune identité : `visiteur` suffit à compter les visiteurs uniques.
 */
const tracker = axios.create({ baseURL: API_URL });

const CLE_VISITEUR = 'visiteur_id';

/** Identifiant anonyme et stable du navigateur — aucune donnée personnelle. */
function idVisiteur(): string {
  let id = localStorage.getItem(CLE_VISITEUR);
  if (!id) {
    id = crypto.randomUUID?.() ?? `${Math.random().toString(36).slice(2)}${Date.now().toString(36)}`;
    localStorage.setItem(CLE_VISITEUR, id);
  }
  return id;
}

/** Extrait l'id de monture d'un chemin de type /montures/12 ou /essai-virtuel/12. */
function montureDepuisChemin(chemin: string): number | undefined {
  const trouve = chemin.match(/^\/(?:montures|essai-virtuel)\/(\d+)/);
  return trouve ? Number(trouve[1]) : undefined;
}

// Le back-office n'est pas de la fréquentation : on ne suit que les pages
// publiques et client.
const PREFIXES_IGNORES = ['/admin', '/opticien'];

export function enregistrerVisite(chemin: string): void {
  if (PREFIXES_IGNORES.some(p => chemin.startsWith(p))) return;

  // Le suivi ne doit jamais perturber la navigation : les échecs sont ignorés.
  tracker
    .post('/stats/visite/', {
      chemin,
      visiteur: idVisiteur(),
      monture: montureDepuisChemin(chemin),
    })
    .catch(() => undefined);
}
