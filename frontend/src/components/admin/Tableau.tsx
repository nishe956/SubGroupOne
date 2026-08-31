import { ReactNode, useEffect, useMemo, useState } from 'react';
import { ChevronLeft, ChevronRight, Inbox } from 'lucide-react';

export interface Colonne<T> {
  cle: string;
  libelle: string;
  /** Les nombres et les montants s'alignent à droite pour se comparer d'un coup d'œil. */
  align?: 'left' | 'right' | 'center';
  className?: string;
  rendu: (ligne: T) => ReactNode;
}

const ALIGN = { left: 'text-left', right: 'text-right', center: 'text-center' };

/**
 * Tableau de données du back-office : zébrures, en-tête discret et pagination
 * intégrée. La pagination est interne parce qu'elle ne porte aucune sémantique
 * métier — elle n'existe que pour garder la page à une hauteur lisible.
 */
export default function Tableau<T>({
  colonnes, lignes, cleLigne, chargement = false, parPage = 8, vide,
}: {
  colonnes: Colonne<T>[];
  lignes: T[];
  cleLigne: (ligne: T) => string | number;
  chargement?: boolean;
  parPage?: number;
  vide?: { titre: string; texte?: string };
}) {
  const [page, setPage] = useState(1);

  // Un changement de filtre rebat les lignes : rester en page 3 renverrait sur
  // un tout autre contenu que celui qu'on vient de demander.
  useEffect(() => { setPage(1); }, [lignes.length]);

  const nbPages = Math.max(1, Math.ceil(lignes.length / parPage));
  // Un filtre qui réduit la liste peut laisser la page courante hors bornes :
  // on la ramène dans l'intervalle au rendu plutôt que d'afficher du vide.
  const pageSure = Math.min(page, nbPages);
  const debut = (pageSure - 1) * parPage;
  const visibles = useMemo(() => lignes.slice(debut, debut + parPage), [lignes, debut, parPage]);

  // Fenêtre glissante de 5 numéros autour de la page courante.
  const numeros = useMemo(() => {
    const premier = Math.max(1, Math.min(pageSure - 2, nbPages - 4));
    return Array.from({ length: Math.min(5, nbPages) }, (_, i) => premier + i);
  }, [pageSure, nbPages]);

  return (
    <div className="bg-white rounded-2xl border border-gray-100 shadow-card overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full min-w-[640px] text-sm">
          <thead>
            <tr className="border-b border-gray-100">
              {colonnes.map(col => (
                <th
                  key={col.cle}
                  scope="col"
                  className={`px-5 py-3.5 text-xs font-medium uppercase tracking-wider text-gray-400 ${ALIGN[col.align ?? 'left']} ${col.className ?? ''}`}
                >
                  {col.libelle}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {chargement ? (
              [...Array(4)].map((_, i) => (
                <tr key={i} className="border-b border-gray-50 last:border-0">
                  {colonnes.map(col => (
                    <td key={col.cle} className="px-5 py-4">
                      <div className="h-3 rounded bg-gray-100 animate-pulse" />
                    </td>
                  ))}
                </tr>
              ))
            ) : visibles.length === 0 ? (
              <tr>
                <td colSpan={colonnes.length} className="px-5 py-16 text-center">
                  <Inbox className="w-9 h-9 mx-auto mb-3 text-gray-300" strokeWidth={1.5} />
                  <div className="font-medium text-gray-700">{vide?.titre ?? 'Aucune donnée'}</div>
                  {vide?.texte && <div className="text-sm text-gray-400 mt-1">{vide.texte}</div>}
                </td>
              </tr>
            ) : (
              visibles.map(ligne => (
                <tr
                  key={cleLigne(ligne)}
                  className="odd:bg-white even:bg-gray-50/70 hover:bg-accent-50/50 transition-colors"
                >
                  {colonnes.map(col => (
                    <td key={col.cle} className={`px-5 py-3.5 ${ALIGN[col.align ?? 'left']} ${col.className ?? ''}`}>
                      {col.rendu(ligne)}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {!chargement && lignes.length > parPage && (
        <div className="flex flex-wrap items-center justify-between gap-3 px-5 py-3.5 border-t border-gray-100">
          <span className="text-xs text-gray-500">
            Affichage {debut + 1}-{Math.min(debut + parPage, lignes.length)} sur {lignes.length}
          </span>
          <nav className="flex items-center gap-1" aria-label="Pagination">
            <BoutonPage onClick={() => setPage(pageSure - 1)} desactive={pageSure === 1} label="Page précédente">
              <ChevronLeft className="w-4 h-4" />
            </BoutonPage>
            {numeros.map(n => (
              <button
                key={n}
                onClick={() => setPage(n)}
                aria-current={n === pageSure ? 'page' : undefined}
                className={`w-8 h-8 rounded-lg text-xs font-medium transition-colors ${
                  n === pageSure
                    ? 'bg-accent-50 text-accent-600 ring-1 ring-inset ring-accent-200'
                    : 'text-gray-500 hover:bg-gray-100'
                }`}
              >
                {n}
              </button>
            ))}
            <BoutonPage onClick={() => setPage(pageSure + 1)} desactive={pageSure === nbPages} label="Page suivante">
              <ChevronRight className="w-4 h-4" />
            </BoutonPage>
          </nav>
        </div>
      )}
    </div>
  );
}

function BoutonPage({ onClick, desactive, label, children }: {
  onClick: () => void; desactive: boolean; label: string; children: ReactNode;
}) {
  return (
    <button
      onClick={onClick}
      disabled={desactive}
      aria-label={label}
      className="w-8 h-8 rounded-lg flex items-center justify-center text-gray-500 hover:bg-gray-100 disabled:opacity-30 disabled:hover:bg-transparent transition-colors"
    >
      {children}
    </button>
  );
}
