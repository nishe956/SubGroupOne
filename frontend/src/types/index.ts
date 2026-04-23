export type Role = 'client' | 'opticien' | 'admin';

export type StatutCommande =
  | 'EN_ATTENTE' | 'VALIDEE' | 'EN_PREPARATION'
  | 'EXPEDIEE' | 'LIVREE' | 'REJETEE' | 'ANNULEE';

export interface User {
  id: number;
  username: string;
  first_name: string;
  last_name: string;
  email: string;
  role: Role;
  telephone?: string;
  adresse?: string;
  date_naissance?: string;
  compagnie_assurance?: number;
  compagnie_assurance_detail?: { id: number; nom: string; taux_prise_charge: number } | null;
  numero_police?: string;
  is_active?: boolean;
}

export interface Boutique {
  id: number;
  nom: string;
  adresse: string;
  telephone?: string;
  description?: string;
  logo?: string;
}

export interface Monture {
  id: number;
  opticien_id?: number;
  nom: string;
  marque: string;
  categorie: string;
  couleur: string;
  forme: string;
  prix: number;
  stock: number;
  images: string[];
  image_principale?: string;
  description?: string;
  actif: boolean;
  created_at: string;
  boutique?: { nom: string; adresse: string; telephone?: string };
}

export interface Ordonnance {
  id: number;
  client?: number;
  client_nom?: string;
  image?: string;
  oeil_droit_sphere?: number;
  oeil_droit_cylindre?: number;
  oeil_droit_axe?: number;
  oeil_gauche_sphere?: number;
  oeil_gauche_cylindre?: number;
  oeil_gauche_axe?: number;
  validee: boolean;
  date_upload: string;
}

export interface CompagnieAssurance {
  id: number;
  nom: string;
  code: string;
  taux_prise_charge: number;
  plafond_annuel?: number;
  telephone?: string;
  email?: string;
  active: boolean;
}

export interface Commande {
  id: number;
  client_id?: number;
  opticien_id?: number;
  monture_id?: number;
  ordonnance_id?: number;
  assurance_id?: number;
  statut: StatutCommande;
  montant_total: number;
  montant_assurance: number;
  montant_client: number;
  notes?: string;
  tracking_code?: string;
  created_at: string;
  updated_at?: string;
  monture?: Monture;
  boutique?: { nom: string };
  ordonnance?: Ordonnance;
  client?: User;
}

export interface Publication {
  id: number;
  auteur?: number;
  auteur_nom?: string;
  titre: string;
  contenu: string;
  image?: string;
  likes: number;
  commentaires_count: number;
  liked?: boolean;
  commentaires?: Commentaire[];
  date_creation: string;
}

export interface Commentaire {
  id: number;
  auteur?: number;
  auteur_nom?: string;
  contenu: string;
  date_creation: string;
}

export interface GroupeFamille {
  id: number;
  nom: string;
  code_invitation: string;
  nb_membres?: number;
  taux_rabais?: number;
  is_chef?: boolean;
  membres?: User[];
}

export interface ClientAnniversaire {
  id: number;
  nom: string;
  label: string;
}

export interface StockOverview {
  total_montures: number;
  total_stock: number;
  valeur_stock: number;
  alertes_count: number;
}

export interface StockAlerte {
  id: number;
  monture: Monture;
  stock_actuel: number;
  seuil_alerte: number;
}

export interface MaintenanceStatut {
  actif: boolean;
  message?: string;
  debut?: string;
}

export interface DashboardStats {
  total_clients: number;
  total_opticiens: number;
  total_commandes: number;
  total_montures: number;
  chiffre_affaires: number;
  commandes_par_statut?: Record<string, number>;
}

export interface Segment {
  nom: string;
  count: number;
  description?: string;
}
