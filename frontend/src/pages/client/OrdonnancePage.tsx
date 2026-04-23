import { useState, useRef } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Upload, FileText, Eye, ArrowRight, Glasses } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import api, { mediaUrl } from '@/lib/api';
import { Ordonnance } from '@/types';
import { interpreterOrdonnance, ProfilVisuel } from '@/utils/ordonnanceUtils';
import toast from 'react-hot-toast';

const COULEURS_PROFIL: Record<string, { bg: string; border: string; text: string; badge: string }> = {
  blue:   { bg: 'bg-blue-50',   border: 'border-blue-200',   text: 'text-blue-800',   badge: 'bg-blue-100 text-blue-700' },
  orange: { bg: 'bg-orange-50', border: 'border-orange-200', text: 'text-orange-800', badge: 'bg-orange-100 text-orange-700' },
  purple: { bg: 'bg-purple-50', border: 'border-purple-200', text: 'text-purple-800', badge: 'bg-purple-100 text-purple-700' },
  pink:   { bg: 'bg-pink-50',   border: 'border-pink-200',   text: 'text-pink-800',   badge: 'bg-pink-100 text-pink-700' },
  green:  { bg: 'bg-green-50',  border: 'border-green-200',  text: 'text-green-800',  badge: 'bg-green-100 text-green-700' },
};

function ProfilBadge({ profil }: { profil: ProfilVisuel }) {
  const c = COULEURS_PROFIL[profil.couleur] || COULEURS_PROFIL.green;
  return (
    <span className={`inline-flex items-center gap-1 text-xs font-semibold px-2.5 py-1 rounded-full ${c.badge}`}>
      <Eye className="w-3 h-3" /> {profil.label}
    </span>
  );
}

export default function OrdonnancePage() {
  const qc = useQueryClient();
  const navigate = useNavigate();
  const fileRef = useRef<HTMLInputElement>(null);
  const [showSaisie, setShowSaisie] = useState<number | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ['ordonnances'],
    queryFn: () => api.get('/ordonnances/').then(r => r.data),
  });

  const ordonnances: Ordonnance[] = data?.results || data || [];

  const uploadMutation = useMutation({
    mutationFn: (file: File) => {
      const fd = new FormData();
      fd.append('image', file);
      return api.post('/ordonnances/ajouter/', fd, { headers: { 'Content-Type': 'multipart/form-data' } });
    },
    onSuccess: () => {
      toast.success("Ordonnance uploadée — valeurs extraites automatiquement !");
      qc.invalidateQueries({ queryKey: ['ordonnances'] });
    },
    onError: (err: unknown) => {
      const msg = (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail || "Erreur lors de l'upload";
      toast.error(msg);
    },
  });

  const handleFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) uploadMutation.mutate(file);
  };

  const derniereOrdonnanceValide = ordonnances.find(o =>
    o.oeil_droit_sphere != null || o.oeil_gauche_sphere != null
  );

  return (
    <div>
      {/* En-tête */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Mes ordonnances</h1>
          <p className="text-sm text-gray-500 mt-1">Uploadez votre ordonnance — l'IA extrait automatiquement les valeurs</p>
        </div>
        <button
          onClick={() => fileRef.current?.click()}
          disabled={uploadMutation.isPending}
          className="btn-primary flex items-center gap-2"
        >
          <Upload className="w-4 h-4" />
          {uploadMutation.isPending ? 'Analyse en cours...' : 'Uploader une ordonnance'}
        </button>
        <input ref={fileRef} type="file" accept="image/*,.pdf" onChange={handleFile} className="hidden" />
      </div>

      {/* Bannière CTA si ordonnance disponible */}
      {derniereOrdonnanceValide && (() => {
        const profil = interpreterOrdonnance(derniereOrdonnanceValide);
        if (!profil) return null;
        const c = COULEURS_PROFIL[profil.couleur] || COULEURS_PROFIL.green;
        return (
          <div className={`rounded-2xl border ${c.border} ${c.bg} p-5 mb-6 flex items-center gap-4`}>
            <div className={`w-12 h-12 rounded-2xl flex items-center justify-center flex-shrink-0 ${c.badge}`}>
              <Glasses className="w-6 h-6" />
            </div>
            <div className="flex-1 min-w-0">
              <div className={`font-semibold ${c.text} mb-0.5`}>
                Votre profil visuel : {profil.label}
              </div>
              <div className={`text-sm opacity-80 ${c.text}`}>
                Nous avons les verres adaptés à votre correction. Choisissez une monture et nous calculons le devis complet.
              </div>
            </div>
            <button
              onClick={() => navigate('/catalogue')}
              className="btn-primary flex items-center gap-2 whitespace-nowrap flex-shrink-0"
            >
              Choisir une monture <ArrowRight className="w-4 h-4" />
            </button>
          </div>
        );
      })()}

      {/* Liste */}
      {isLoading ? (
        <div className="grid gap-4">{[...Array(3)].map((_, i) => <div key={i} className="h-40 bg-gray-100 animate-pulse rounded-2xl" />)}</div>
      ) : ordonnances.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <FileText className="w-12 h-12 mx-auto mb-3 opacity-40" />
          <p className="font-medium mb-1">Aucune ordonnance</p>
          <p className="text-sm">Uploadez la photo de votre ordonnance pour commencer</p>
        </div>
      ) : (
        <div className="grid gap-4">
          {ordonnances.map(o => {
            const profil = interpreterOrdonnance(o);
            const hasSaisie = showSaisie === o.id;

            return (
              <div key={o.id} className="card">
                <div className="flex gap-4">
                  {o.image && (
                    <img
                      src={mediaUrl(o.image)}
                      alt="Ordonnance"
                      loading="lazy"
                      className="w-20 h-20 object-cover rounded-xl flex-shrink-0 border border-gray-100"
                    />
                  )}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-2 flex-wrap">
                      <FileText className="w-4 h-4 text-primary-600 flex-shrink-0" />
                      <span className="font-medium text-gray-900">Ordonnance</span>
                      {o.validee && <span className="badge bg-green-100 text-green-700">Validée par l'opticien</span>}
                      {profil && <ProfilBadge profil={profil} />}
                    </div>

                    {/* Valeurs optiques */}
                    {(o.oeil_droit_sphere != null || o.oeil_gauche_sphere != null) ? (
                      <div className="grid grid-cols-3 gap-1.5 text-xs mb-3">
                        {([
                          ['OD — Sphère', o.oeil_droit_sphere],
                          ['OD — Cylindre', o.oeil_droit_cylindre],
                          ['OD — Axe', o.oeil_droit_axe],
                          ['OG — Sphère', o.oeil_gauche_sphere],
                          ['OG — Cylindre', o.oeil_gauche_cylindre],
                          ['OG — Axe', o.oeil_gauche_axe],
                        ] as [string, number | undefined][]).map(([label, val]) => (
                          <div key={label} className="bg-gray-50 rounded-lg p-2 text-center">
                            <div className="text-gray-400 text-[10px] leading-tight">{label}</div>
                            <div className="font-semibold text-gray-800 mt-0.5">
                              {val != null ? (val >= 0 && label.includes('Sphère') ? `+${val}` : val) : '—'}
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <div className="mb-3">
                        <button
                          onClick={() => setShowSaisie(hasSaisie ? null : o.id)}
                          className="text-xs text-primary-600 hover:underline"
                        >
                          {hasSaisie ? 'Masquer' : "Valeurs non extraites — saisir manuellement"}
                        </button>
                        {hasSaisie && (
                          <p className="text-xs text-gray-400 mt-1">
                            Veuillez contacter votre opticien pour saisir les valeurs manuellement.
                          </p>
                        )}
                      </div>
                    )}

                    {/* Interprétation */}
                    {profil && (
                      <div className="text-xs text-gray-500 mb-3 flex items-start gap-1.5">
                        <Eye className="w-3.5 h-3.5 mt-0.5 flex-shrink-0 text-primary-400" />
                        <span>
                          <strong>Profil :</strong> {profil.label} ({profil.description}).
                          {' '}Verres recommandés :{' '}
                          {profil.verresRecommandes.map(id => {
                            const noms: Record<string, string> = {
                              unifocal_simple: 'simples unifocaux',
                              unifocal_mince: 'amincis (ind. 1.6)',
                              torique: 'toriques',
                              progressif: 'progressifs',
                            };
                            return noms[id] || id;
                          }).join(', ')}.
                        </span>
                      </div>
                    )}

                    <div className="flex items-center justify-between flex-wrap gap-2">
                      <span className="text-xs text-gray-400">
                        {new Date(o.date_upload).toLocaleDateString('fr-FR', { year: 'numeric', month: 'long', day: 'numeric' })}
                      </span>
                      {(o.oeil_droit_sphere != null || o.oeil_gauche_sphere != null) && (
                        <button
                          onClick={() => navigate('/catalogue')}
                          className="flex items-center gap-1.5 text-xs font-semibold text-primary-600 hover:text-primary-700 bg-primary-50 hover:bg-primary-100 px-3 py-1.5 rounded-full transition-all"
                        >
                          Choisir une monture <ArrowRight className="w-3 h-3" />
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
