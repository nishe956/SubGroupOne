import { Check } from 'lucide-react';
import { formatCFA } from '@/lib/api';
import { TYPES_VERRES, OPTIONS_VERRES, ProfilVisuel } from '@/utils/ordonnanceUtils';

interface Props {
  typeVerreId: string;
  setTypeVerreId: (id: string) => void;
  optionsChoisies: string[];
  setOptionsChoisies: (opts: string[]) => void;
  profil: ProfilVisuel | null;
}

const COULEURS_PROFIL: Record<string, string> = {
  blue: 'bg-blue-50 border-blue-200 text-blue-800',
  orange: 'bg-orange-50 border-orange-200 text-orange-800',
  purple: 'bg-purple-50 border-purple-200 text-purple-800',
  pink: 'bg-pink-50 border-pink-200 text-pink-800',
  green: 'bg-green-50 border-green-200 text-green-800',
};

export default function VerreSelector({ typeVerreId, setTypeVerreId, optionsChoisies, setOptionsChoisies, profil }: Props) {
  const toggleOption = (id: string) => {
    setOptionsChoisies(
      optionsChoisies.includes(id)
        ? optionsChoisies.filter(o => o !== id)
        : [...optionsChoisies, id]
    );
  };

  return (
    <div className="space-y-4">
      {/* Profil visuel */}
      {profil && (
        <div className={`rounded-xl border px-4 py-3 text-sm ${COULEURS_PROFIL[profil.couleur] || 'bg-gray-50 border-gray-200 text-gray-700'}`}>
          <div className="font-semibold mb-0.5">👁 {profil.label}</div>
          <div className="opacity-80 text-xs">D'après votre ordonnance : {profil.description}</div>
        </div>
      )}

      {/* Type de verre */}
      <div>
        <div className="text-sm font-medium text-gray-700 mb-2">Type de verre</div>
        <div className="space-y-2">
          {TYPES_VERRES.map(t => {
            const recommande = profil?.verresRecommandes.includes(t.id);
            const selected = typeVerreId === t.id;
            return (
              <button
                key={t.id}
                type="button"
                onClick={() => setTypeVerreId(t.id)}
                className={`w-full flex items-start gap-3 p-3 rounded-xl border-2 text-left transition-all ${
                  selected
                    ? 'border-primary-500 bg-primary-50'
                    : 'border-gray-200 bg-white hover:border-gray-300'
                }`}
              >
                <div className={`mt-0.5 w-4 h-4 rounded-full border-2 flex-shrink-0 flex items-center justify-center ${
                  selected ? 'border-primary-500 bg-primary-500' : 'border-gray-300'
                }`}>
                  {selected && <div className="w-1.5 h-1.5 rounded-full bg-white" />}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-sm font-medium text-gray-900">{t.nom}</span>
                    {t.tag && (
                      <span className="text-xs px-1.5 py-0.5 rounded-full bg-primary-100 text-primary-700 font-medium">
                        {t.tag}
                      </span>
                    )}
                    {recommande && !t.tag && (
                      <span className="text-xs px-1.5 py-0.5 rounded-full bg-green-100 text-green-700 font-medium">
                        ✓ Adapté
                      </span>
                    )}
                  </div>
                  <div className="text-xs text-gray-500 mt-0.5">{t.description}</div>
                </div>
                <div className="text-sm font-bold text-gray-900 flex-shrink-0">{formatCFA(t.prix)}</div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Options supplémentaires */}
      <div>
        <div className="text-sm font-medium text-gray-700 mb-2">Options supplémentaires</div>
        <div className="space-y-2">
          {OPTIONS_VERRES.map(opt => {
            const checked = optionsChoisies.includes(opt.id);
            return (
              <button
                key={opt.id}
                type="button"
                onClick={() => toggleOption(opt.id)}
                className={`w-full flex items-center gap-3 p-3 rounded-xl border-2 text-left transition-all ${
                  checked ? 'border-primary-400 bg-primary-50' : 'border-gray-200 bg-white hover:border-gray-300'
                }`}
              >
                <div className={`w-4 h-4 rounded border-2 flex-shrink-0 flex items-center justify-center transition-colors ${
                  checked ? 'border-primary-500 bg-primary-500' : 'border-gray-300'
                }`}>
                  {checked && <Check className="w-2.5 h-2.5 text-white" />}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-sm font-medium text-gray-900">{opt.nom}</div>
                  <div className="text-xs text-gray-500">{opt.description}</div>
                </div>
                <div className="text-sm font-semibold text-gray-700 flex-shrink-0">+{formatCFA(opt.prix)}</div>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
