import { Sparkles } from 'lucide-react';
import {
  QUESTIONS_CONCEPTION,
  ReponsesConception,
  RecommandationVerres,
} from '@/utils/ordonnanceUtils';

interface Props {
  reponses: ReponsesConception;
  setReponses: (r: ReponsesConception) => void;
  recommandation: RecommandationVerres | null;
}

/**
 * Questionnaire d'usage : le client participe à la conception de ses verres.
 * Les réponses alimentent une recommandation (calculée en amont) affichée en bas.
 */
export default function QuestionnaireConception({ reponses, setReponses, recommandation }: Props) {
  const repondre = (questionId: string, optionId: string) =>
    setReponses({ ...reponses, [questionId]: optionId });

  const nbRepondues = QUESTIONS_CONCEPTION.filter(q => reponses[q.id]).length;

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div className="text-sm text-gray-500">
          {nbRepondues} / {QUESTIONS_CONCEPTION.length} questions
        </div>
        <div className="flex-1 mx-3 h-1.5 bg-gray-100 rounded-full overflow-hidden max-w-[160px]">
          <div
            className="h-full bg-primary-500 rounded-full transition-all"
            style={{ width: `${(nbRepondues / QUESTIONS_CONCEPTION.length) * 100}%` }}
          />
        </div>
      </div>

      {QUESTIONS_CONCEPTION.map((q, i) => (
        <div key={q.id}>
          <div className="text-sm font-semibold text-gray-900 mb-0.5">
            {i + 1}. {q.question}
          </div>
          {q.aide && <div className="text-xs text-gray-500 mb-2">{q.aide}</div>}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 mt-2">
            {q.options.map(opt => {
              const selected = reponses[q.id] === opt.id;
              return (
                <button
                  key={opt.id}
                  type="button"
                  onClick={() => repondre(q.id, opt.id)}
                  className={`flex items-center gap-2 p-2.5 rounded-xl border-2 text-left text-sm transition-all ${
                    selected
                      ? 'border-primary-500 bg-primary-50 text-primary-800'
                      : 'border-gray-200 bg-white text-gray-700 hover:border-gray-300'
                  }`}
                >
                  {opt.emoji && <span className="text-base leading-none">{opt.emoji}</span>}
                  <span className="flex-1">{opt.label}</span>
                </button>
              );
            })}
          </div>
        </div>
      ))}

      {/* Recommandation */}
      {recommandation && recommandation.explications.length > 0 && (
        <div className="rounded-xl border-2 border-primary-200 bg-primary-50 p-4">
          <div className="flex items-center gap-2 text-primary-800 font-semibold text-sm mb-2">
            <Sparkles className="w-4 h-4" /> Notre recommandation
          </div>
          <ul className="space-y-1">
            {recommandation.explications.map((e, i) => (
              <li key={i} className="text-xs text-primary-700 flex items-start gap-1.5">
                <span className="text-primary-400 mt-0.5">•</span>
                <span>{e}</span>
              </li>
            ))}
          </ul>
          <p className="text-xs text-gray-500 mt-2">
            Vous pouvez ajuster ce choix ci-dessous ; l'opticien recevra vos réponses.
          </p>
        </div>
      )}
    </div>
  );
}
