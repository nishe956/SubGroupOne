import { ReactNode } from 'react';

/** Titre de page + actions, identique d'un écran d'administration à l'autre. */
export default function EnTetePage({ titre, sousTitre, children }: {
  titre: string; sousTitre?: string; children?: ReactNode;
}) {
  return (
    <div className="flex flex-wrap items-start justify-between gap-3 mb-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-gray-900">{titre}</h1>
        {sousTitre && <p className="text-sm text-gray-500 mt-1">{sousTitre}</p>}
      </div>
      {children && <div className="flex items-center gap-2">{children}</div>}
    </div>
  );
}
