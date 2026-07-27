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

// ─────────────────────────────────────────────────────────────────────────
// Questionnaire de conception des verres
// Le client répond à des questions d'usage ; combinées à l'ordonnance (profil
// visuel), elles déterminent une recommandation de verre + traitements.
// ─────────────────────────────────────────────────────────────────────────

export interface QuestionConception {
  id: string;
  question: string;
  aide?: string;
  options: { id: string; label: string; emoji?: string }[];
}

export const QUESTIONS_CONCEPTION: QuestionConception[] = [
  {
    id: 'usage_principal',
    question: 'Quel sera l\'usage principal de vos lunettes ?',
    aide: 'Cela nous aide à choisir le type de verre le plus adapté.',
    options: [
      { id: 'ecran', label: 'Travail sur écran / bureau', emoji: '💻' },
      { id: 'conduite', label: 'Conduite', emoji: '🚗' },
      { id: 'lecture', label: 'Lecture / vision de près', emoji: '📖' },
      { id: 'exterieur', label: 'Extérieur / sport', emoji: '🌳' },
      { id: 'polyvalent', label: 'Usage polyvalent', emoji: '✨' },
    ],
  },
  {
    id: 'temps_ecran',
    question: 'Combien de temps passez-vous devant un écran chaque jour ?',
    options: [
      { id: 'faible', label: 'Moins de 2 h', emoji: '🌤' },
      { id: 'moyen', label: 'Entre 2 h et 6 h', emoji: '🕑' },
      { id: 'eleve', label: 'Plus de 6 h', emoji: '🌙' },
    ],
  },
  {
    id: 'conduite_nuit',
    question: 'Conduisez-vous souvent la nuit ?',
    aide: 'Un traitement anti-reflets améliore le confort nocturne.',
    options: [
      { id: 'oui', label: 'Oui, régulièrement', emoji: '🌃' },
      { id: 'non', label: 'Rarement ou jamais', emoji: '☀️' },
    ],
  },
  {
    id: 'soleil',
    question: 'Êtes-vous souvent exposé au soleil ?',
    options: [
      { id: 'souvent', label: 'Souvent', emoji: '🏖' },
      { id: 'parfois', label: 'Parfois', emoji: '⛅' },
      { id: 'rarement', label: 'Rarement', emoji: '🏠' },
    ],
  },
  {
    id: 'vision_pres_loin',
    question: 'Avez-vous du mal à voir à la fois de près ET de loin ?',
    aide: 'Cela peut indiquer une presbytie, mieux corrigée par des verres progressifs.',
    options: [
      { id: 'oui', label: 'Oui', emoji: '👓' },
      { id: 'non', label: 'Non', emoji: '👁' },
    ],
  },
];

export type ReponsesConception = Record<string, string>;

export interface RecommandationVerres {
  typeVerreId: string;
  optionsIds: string[];
  explications: string[];
}

/**
 * Combine le profil visuel (issu de l'ordonnance) et les réponses du client
 * pour recommander un type de verre et des traitements.
 */
export function recommanderVerres(
  profil: ProfilVisuel | null,
  reponses: ReponsesConception,
): RecommandationVerres {
  const explications: string[] = [];
  const optionsIds = new Set<string>();

  // 1) Type de verre : d'abord la contrainte médicale, puis l'usage.
  let typeVerreId = 'unifocal_simple';

  if (reponses.vision_pres_loin === 'oui') {
    typeVerreId = 'progressif';
    explications.push('Vision de près et de loin difficile → verres progressifs.');
  } else if (profil?.astigmate) {
    typeVerreId = 'torique';
    explications.push('Astigmatisme détecté sur l\'ordonnance → verres toriques.');
  } else if (profil?.myope || profil?.hypermetrope) {
    typeVerreId = 'unifocal_mince';
    explications.push('Correction simple → verres unifocaux amincis, plus légers.');
  }

  // 2) Traitements selon l'usage.
  if (reponses.temps_ecran === 'eleve' || reponses.usage_principal === 'ecran') {
    optionsIds.add('antiblue');
    optionsIds.add('anti_reflets');
    explications.push('Exposition écran importante → filtre lumière bleue + anti-reflets.');
  }
  if (reponses.conduite_nuit === 'oui' || reponses.usage_principal === 'conduite') {
    optionsIds.add('anti_reflets');
    explications.push('Conduite (notamment de nuit) → traitement anti-reflets.');
  }
  if (reponses.soleil === 'souvent' || reponses.usage_principal === 'exterieur') {
    optionsIds.add('photochromique');
    optionsIds.add('uv');
    explications.push('Exposition solaire fréquente → verres photochromiques + protection UV.');
  } else if (reponses.soleil === 'parfois') {
    optionsIds.add('uv');
    explications.push('Protection UV recommandée pour préserver vos yeux.');
  }

  return { typeVerreId, optionsIds: [...optionsIds], explications };
}

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
