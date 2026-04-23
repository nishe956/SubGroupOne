import { Ordonnance } from '@/types';

export interface ProfilVisuel {
  myope: boolean;
  hypermetrope: boolean;
  astigmate: boolean;
  label: string;
  description: string;
  couleur: string;
  verresRecommandes: string[];
}

export function interpreterOrdonnance(o: Ordonnance): ProfilVisuel | null {
  const odSph = o.oeil_droit_sphere ?? 0;
  const ogSph = o.oeil_gauche_sphere ?? 0;
  const odCyl = o.oeil_droit_cylindre ?? 0;
  const ogCyl = o.oeil_gauche_cylindre ?? 0;

  const aDesValeurs = o.oeil_droit_sphere != null || o.oeil_gauche_sphere != null;
  if (!aDesValeurs) return null;

  const myope = odSph < -0.25 || ogSph < -0.25;
  const hypermetrope = odSph > 0.25 || ogSph > 0.25;
  const astigmate = Math.abs(odCyl) > 0.25 || Math.abs(ogCyl) > 0.25;

  const labels: string[] = [];
  const descriptions: string[] = [];
  const verres: string[] = [];

  if (myope) {
    labels.push('Myopie');
    descriptions.push('vision de loin floue');
    verres.push('unifocal_simple', 'unifocal_mince');
  }
  if (hypermetrope) {
    labels.push('Hypermétropie');
    descriptions.push('vision de près difficile');
    verres.push('unifocal_simple', 'unifocal_mince');
  }
  if (astigmate) {
    labels.push('Astigmatisme');
    descriptions.push('vision déformée');
    verres.push('torique');
  }

  if (!myope && !hypermetrope && !astigmate) {
    labels.push('Correction légère');
    descriptions.push('légère correction nécessaire');
    verres.push('unifocal_simple');
  }

  const couleur = myope && astigmate ? 'purple'
    : myope ? 'blue'
    : hypermetrope ? 'orange'
    : astigmate ? 'pink'
    : 'green';

  return {
    myope,
    hypermetrope,
    astigmate,
    label: labels.join(' + '),
    description: descriptions.join(', '),
    couleur,
    verresRecommandes: [...new Set(verres)],
  };
}

export interface TypeVerre {
  id: string;
  nom: string;
  description: string;
  prix: number;
  tag?: string;
}

export interface OptionVerre {
  id: string;
  nom: string;
  description: string;
  prix: number;
}

export const TYPES_VERRES: TypeVerre[] = [
  {
    id: 'unifocal_simple',
    nom: 'Verres simples unifocaux',
    description: 'Correction unique — myopie ou hypermétropie',
    prix: 15000,
  },
  {
    id: 'unifocal_mince',
    nom: 'Verres amincis (indice 1.6)',
    description: 'Plus légers et esthétiques pour corrections fortes',
    prix: 28000,
    tag: 'Recommandé',
  },
  {
    id: 'torique',
    nom: 'Verres toriques',
    description: 'Correction de l\'astigmatisme en plus de la myopie/hypermétropie',
    prix: 32000,
  },
  {
    id: 'progressif',
    nom: 'Verres progressifs',
    description: 'Vision de près, intermédiaire et de loin — presbytie',
    prix: 55000,
    tag: 'Presbytie',
  },
];

export const OPTIONS_VERRES: OptionVerre[] = [
  {
    id: 'anti_reflets',
    nom: 'Traitement anti-reflets',
    description: 'Réduit les reflets pour un confort visuel optimal',
    prix: 8000,
  },
  {
    id: 'photochromique',
    nom: 'Verres photochromiques',
    description: 'S\'assombrissent automatiquement en plein soleil',
    prix: 20000,
  },
  {
    id: 'antiblue',
    nom: 'Filtre lumière bleue',
    description: 'Protège des écrans (télévision, téléphone, ordinateur)',
    prix: 6000,
  },
  {
    id: 'uv',
    nom: 'Protection UV 400',
    description: 'Blocage total des rayons UV pour protéger vos yeux',
    prix: 4000,
  },
];
