import { useEffect, useState } from 'react';
import { FileText } from 'lucide-react';
import api from '@/lib/api';

/**
 * Vignette d'une ordonnance.
 *
 * L'image ne peut pas être chargée par un `<img src="/media/...">` : les
 * ordonnances sont des données de santé et ne sont plus servies par une URL
 * publique. Elles passent par un endpoint authentifié qui revérifie les droits
 * d'accès à chaque requête — il faut donc la récupérer avec le jeton, puis la
 * transformer en URL de blob locale.
 */
export default function ImageOrdonnance({
  id,
  className = '',
  onClick,
}: {
  id: number;
  className?: string;
  onClick?: () => void;
}) {
  const [url, setUrl] = useState<string | null>(null);
  const [echec, setEchec] = useState(false);

  useEffect(() => {
    let annule = false;
    let blobUrl: string | null = null;

    api
      .get(`/ordonnances/${id}/image/`, { responseType: 'blob' })
      .then(res => {
        if (annule) return;
        blobUrl = URL.createObjectURL(res.data);
        setUrl(blobUrl);
      })
      .catch(() => { if (!annule) setEchec(true); });

    // Libère l'URL de blob : sans ça, chaque affichage laisse l'image en
    // mémoire jusqu'au rechargement de la page.
    return () => {
      annule = true;
      if (blobUrl) URL.revokeObjectURL(blobUrl);
    };
  }, [id]);

  const base = `w-20 h-20 rounded-xl flex-shrink-0 border border-gray-100 ${className}`;

  if (echec) {
    return (
      <div className={`${base} bg-gray-50 flex items-center justify-center`} title="Aperçu indisponible">
        <FileText className="w-6 h-6 text-gray-300" />
      </div>
    );
  }

  if (!url) {
    return <div className={`${base} bg-gray-100 animate-pulse`} aria-hidden="true" />;
  }

  return (
    <img
      src={url}
      alt="Ordonnance"
      onClick={onClick}
      // Une ordonnance peut être un PDF : le blob se télécharge bien mais ne
      // se rend pas comme une image, d'où le repli sur l'icône.
      onError={() => setEchec(true)}
      className={`${base} object-cover ${onClick ? 'cursor-zoom-in' : ''}`}
    />
  );
}
