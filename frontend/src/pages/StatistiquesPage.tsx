import { useState, ReactNode } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  ResponsiveContainer, AreaChart, Area, LineChart, Line, BarChart, Bar,
  XAxis, YAxis, CartesianGrid, Tooltip, Legend,
} from 'recharts';
import { TrendingUp, TrendingDown, Minus, Table2, ChartColumn } from 'lucide-react';
import api, { formatCFA } from '@/lib/api';
import { useAuth } from '@/contexts/AuthContext';

/* -------------------------------------------------------------------------- */
/* Données                                                                     */
/* -------------------------------------------------------------------------- */

interface PointVente   { label: string; ca: number; nb: number }
interface PointVisite  { label: string; visites: number; uniques: number }
interface PointClient  { label: string; valeur: number }

interface Analytique {
  periode: string;
  granularite: 'jour' | 'mois';
  clients_label: string;
  resume: {
    ca: number;
    ca_evolution: number | null;
    ventes: number;
    panier_moyen: number;
    visites: number;
    visites_evolution: number | null;
    visiteurs_uniques: number;
    taux_conversion: number | null;
    nouveaux_clients: number;
    taux_validation: number | null;
    commandes_total: number;
  };
  series: { ventes: PointVente[]; visites: PointVisite[]; clients: PointClient[] };
  commandes_par_statut: Record<string, number>;
  methodes_paiement: Record<string, number>;
  top_montures: { id: number; nom: string; marque: string; vues: number; ventes: number }[];
  pages_populaires: { chemin: string; vues: number }[];
}

const PERIODES = [
  { cle: '7j',  libelle: '7 jours' },
  { cle: '30j', libelle: '30 jours' },
  { cle: '90j', libelle: '90 jours' },
  { cle: '12m', libelle: '12 mois' },
];

const LIBELLES_STATUT: Record<string, string> = {
  en_attente:     'En attente',
  validee:        'Validée',
  rejetee:        'Rejetée',
  en_preparation: 'En préparation',
  livree:         'Livrée',
};

const LIBELLES_PAIEMENT: Record<string, string> = {
  carte_bancaire: 'Carte bancaire',
  orange_money:   'Orange Money',
  wave:           'Wave',
};

/* -------------------------------------------------------------------------- */
/* Palette                                                                     */
/* -------------------------------------------------------------------------- */

/**
 * Les deux espaces qui affichent cette page — administration et opticien —
 * posent leurs cartes sur du blanc : une seule palette suffit désormais.
 * Les teintes de série (s1/s2) proviennent de la palette catégorielle validée
 * (séparation daltonisme et contraste vérifiés sur surface blanche) ; la grille
 * et les axes reprennent l'échelle de gris Tailwind déjà utilisée par l'app,
 * pour rester en retrait d'un cran sur la surface.
 */
const COULEURS = {
  carte: 'bg-white border border-gray-100 shadow-card',
  titre: 'text-gray-900', sousTitre: 'text-gray-500', valeur: 'text-gray-900',
  grille: '#e5e7eb', axe: '#d1d5db', tickTexte: '#6b7280',
  fondInfobulle: '#ffffff', bordInfobulle: '#e5e7eb', texteInfobulle: '#111827',
  s1: '#2a78d6', s2: '#eb6834', bon: '#0ca30c', mauvais: '#d03b3b',
};

type Couleurs = typeof COULEURS;

/* -------------------------------------------------------------------------- */
/* Briques d'affichage                                                         */
/* -------------------------------------------------------------------------- */

function Delta({ valeur, c }: { valeur: number | null; c: Couleurs }) {
  // Pas de base de comparaison : on l'affiche franchement plutôt que « +100 % ».
  if (valeur === null || valeur === undefined) {
    return (
      <span className={`inline-flex items-center gap-1 text-xs ${c.sousTitre}`}>
        <Minus className="w-3 h-3" /> pas de comparatif
      </span>
    );
  }
  const positif = valeur >= 0;
  const Icone = positif ? TrendingUp : TrendingDown;
  return (
    <span
      className="inline-flex items-center gap-1 text-xs font-medium"
      style={{ color: positif ? c.bon : c.mauvais }}
    >
      <Icone className="w-3 h-3" />
      {positif ? '+' : ''}{valeur} % vs période précédente
    </span>
  );
}

function Tuile({ libelle, valeur, delta, c }: {
  libelle: string; valeur: string; delta?: number | null; c: Couleurs;
}) {
  return (
    <div className={`${c.carte} rounded-2xl p-5`}>
      <div className={`text-sm ${c.sousTitre} mb-1`}>{libelle}</div>
      {/* Chiffres proportionnels : tabular-nums alourdirait un grand nombre isolé. */}
      <div className={`text-2xl font-bold ${c.valeur} mb-1`}>{valeur}</div>
      {delta !== undefined && <Delta valeur={delta} c={c} />}
    </div>
  );
}

function Infobulle({ active, payload, label, c, unite }: any) {
  if (!active || !payload?.length) return null;
  return (
    <div
      className="rounded-xl px-3 py-2 text-xs shadow-lg"
      style={{
        background: c.fondInfobulle,
        border: `1px solid ${c.bordInfobulle}`,
        color: c.texteInfobulle,
      }}
    >
      <div className="font-semibold mb-1">{label}</div>
      {payload.map((p: any) => (
        <div key={p.dataKey} className="flex items-center gap-2">
          <span className="w-2 h-2 rounded-full" style={{ background: p.color }} />
          <span>{p.name}</span>
          <span className="font-semibold ml-auto tabular-nums">
            {unite === 'cfa' ? formatCFA(p.value) : p.value.toLocaleString('fr-FR')}
          </span>
        </div>
      ))}
    </div>
  );
}

interface Colonne { cle: string; libelle: string; cfa?: boolean }

/**
 * Carte de graphique avec sa vue tableau jumelle : toute valeur lisible dans le
 * graphique doit aussi l'être sans dépendre de la couleur ni du survol.
 */
function CarteGraphique({ titre, sousTitre, c, donnees, colonnes, children }: {
  titre: string; sousTitre?: string; c: Couleurs;
  donnees: any[]; colonnes: Colonne[]; children: ReactNode;
}) {
  const [tableau, setTableau] = useState(false);
  return (
    <div className={`${c.carte} rounded-2xl p-5`}>
      <div className="flex items-start justify-between mb-4 gap-3">
        <div>
          <h2 className={`font-semibold ${c.titre}`}>{titre}</h2>
          {sousTitre && <p className={`text-xs ${c.sousTitre} mt-0.5`}>{sousTitre}</p>}
        </div>
        <button
          onClick={() => setTableau(t => !t)}
          className={`flex items-center gap-1.5 text-xs ${c.sousTitre} hover:opacity-70 transition-opacity flex-shrink-0`}
          aria-label={tableau ? 'Afficher le graphique' : 'Afficher les données en tableau'}
        >
          {tableau ? <ChartColumn className="w-4 h-4" /> : <Table2 className="w-4 h-4" />}
          {tableau ? 'Graphique' : 'Données'}
        </button>
      </div>

      {tableau ? (
        <div className="overflow-x-auto max-h-[280px]">
          <table className="w-full text-sm">
            <thead>
              <tr className={`text-left ${c.sousTitre} text-xs`}>
                {colonnes.map(col => <th key={col.cle} className="py-2 pr-4 font-medium">{col.libelle}</th>)}
              </tr>
            </thead>
            <tbody>
              {donnees.map((ligne, i) => (
                <tr key={i} className={c.valeur}>
                  {colonnes.map(col => (
                    <td key={col.cle} className="py-1.5 pr-4 tabular-nums">
                      {col.cfa ? formatCFA(ligne[col.cle]) : ligne[col.cle]}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="h-[280px]">{children}</div>
      )}
    </div>
  );
}

/** Barres horizontales pour une répartition par catégorie (une mesure, une couleur). */
function Repartition({ titre, entrees, total, c, vide }: {
  titre: string; entrees: [string, number][]; total: number; c: Couleurs; vide: string;
}) {
  return (
    <div className={`${c.carte} rounded-2xl p-5`}>
      <h2 className={`font-semibold ${c.titre} mb-4`}>{titre}</h2>
      {entrees.length === 0 ? (
        <p className={`text-sm ${c.sousTitre}`}>{vide}</p>
      ) : (
        <div className="space-y-3">
          {entrees.map(([libelle, nb]) => (
            <div key={libelle}>
              <div className="flex items-center justify-between text-sm mb-1">
                <span className={c.valeur}>{libelle}</span>
                <span className={`${c.sousTitre} tabular-nums`}>
                  {nb} {total > 0 && `· ${Math.round((nb / total) * 100)} %`}
                </span>
              </div>
              <div className="h-2 rounded-full overflow-hidden" style={{ background: c.grille }}>
                <div
                  className="h-full rounded-full"
                  style={{ width: total ? `${(nb / total) * 100}%` : '0%', background: c.s1 }}
                />
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

/* -------------------------------------------------------------------------- */
/* Page                                                                        */
/* -------------------------------------------------------------------------- */

export default function StatistiquesPage() {
  const { user } = useAuth();
  const estAdmin = user?.role === 'admin';
  const c = COULEURS;

  const [periode, setPeriode] = useState('30j');

  const { data, isLoading, isFetching } = useQuery<Analytique>({
    queryKey: ['stats-analytique', periode],
    queryFn: () => api.get(`/stats/analytique/?periode=${periode}`).then(r => r.data),
    // Conserve l'affichage précédent pendant le rechargement : pas de squelette
    // clignotant ni de saut de mise en page au changement de période.
    placeholderData: prev => prev,
  });

  if (isLoading) {
    return (
      <div className="flex justify-center py-20">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary-600" />
      </div>
    );
  }
  if (!data) return null;

  const { resume, series } = data;
  const axe = { stroke: c.axe, tick: { fill: c.tickTexte, fontSize: 11 }, tickLine: false };

  const statuts = Object.entries(data.commandes_par_statut)
    .map(([k, v]) => [LIBELLES_STATUT[k] || k, v] as [string, number])
    .sort((a, b) => b[1] - a[1]);
  const paiements = Object.entries(data.methodes_paiement)
    .map(([k, v]) => [LIBELLES_PAIEMENT[k] || k, v] as [string, number])
    .sort((a, b) => b[1] - a[1]);

  return (
    <div>
      {/* En-tête + filtre de période : une seule barre de filtres, au-dessus de
          tout ce qu'elle pilote. */}
      <div className="flex flex-wrap items-center justify-between gap-3 mb-6">
        <div>
          <h1 className={`text-2xl font-bold ${c.titre}`}>Statistiques</h1>
          <p className={`text-sm ${c.sousTitre} mt-1`}>
            {estAdmin ? "Activité de l'ensemble du réseau" : 'Activité de votre boutique'}
          </p>
        </div>
        <div className="flex gap-1" role="group" aria-label="Période">
          {PERIODES.map(p => (
            <button
              key={p.cle}
              onClick={() => setPeriode(p.cle)}
              aria-pressed={periode === p.cle}
              className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                periode === p.cle
                  ? 'bg-gray-900 text-white'
                  : 'text-gray-500 hover:bg-gray-100'
              }`}
            >
              {p.libelle}
            </button>
          ))}
        </div>
      </div>

      <div className={`space-y-6 transition-opacity ${isFetching ? 'opacity-60' : 'opacity-100'}`}>
        {/* Chiffres clés */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <Tuile libelle="Chiffre d'affaires" valeur={formatCFA(resume.ca)} delta={resume.ca_evolution} c={c} />
          <Tuile libelle="Ventes livrées" valeur={resume.ventes.toLocaleString('fr-FR')} c={c} />
          <Tuile libelle="Panier moyen" valeur={formatCFA(resume.panier_moyen)} c={c} />
          <Tuile libelle="Commandes reçues" valeur={resume.commandes_total.toLocaleString('fr-FR')} c={c} />
          <Tuile libelle="Visites" valeur={resume.visites.toLocaleString('fr-FR')} delta={resume.visites_evolution} c={c} />
          <Tuile libelle="Visiteurs uniques" valeur={resume.visiteurs_uniques.toLocaleString('fr-FR')} c={c} />
          <Tuile
            libelle="Taux de conversion"
            valeur={resume.taux_conversion === null ? '—' : `${resume.taux_conversion} %`}
            c={c}
          />
          <Tuile libelle={data.clients_label} valeur={resume.nouveaux_clients.toLocaleString('fr-FR')} c={c} />
        </div>

        {/* Chiffre d'affaires — une seule série, donc pas de légende : le titre la nomme. */}
        <CarteGraphique
          titre="Chiffre d'affaires"
          sousTitre={`Par ${data.granularite} · commandes livrées`}
          c={c}
          donnees={series.ventes}
          colonnes={[
            { cle: 'label', libelle: 'Période' },
            { cle: 'ca', libelle: "Chiffre d'affaires", cfa: true },
            { cle: 'nb', libelle: 'Ventes' },
          ]}
        >
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={series.ventes} margin={{ top: 8, right: 8, bottom: 0, left: 0 }}>
              <defs>
                <linearGradient id="grad-ca" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor={c.s1} stopOpacity={0.28} />
                  <stop offset="100%" stopColor={c.s1} stopOpacity={0.02} />
                </linearGradient>
              </defs>
              <CartesianGrid stroke={c.grille} vertical={false} />
              <XAxis dataKey="label" {...axe} interval="preserveStartEnd" minTickGap={24} />
              <YAxis {...axe} width={72} tickFormatter={v => (v >= 1000 ? `${v / 1000}k` : v)} />
              <Tooltip content={<Infobulle c={c} unite="cfa" />} />
              <Area
                type="monotone" dataKey="ca" name="Chiffre d'affaires"
                stroke={c.s1} strokeWidth={2} fill="url(#grad-ca)"
                activeDot={{ r: 5, strokeWidth: 2, stroke: c.fondInfobulle }}
              />
            </AreaChart>
          </ResponsiveContainer>
        </CarteGraphique>

        {/* Fréquentation — deux séries de même unité, donc un seul axe + légende. */}
        <CarteGraphique
          titre="Fréquentation"
          sousTitre={`Pages vues et visiteurs uniques par ${data.granularite}`}
          c={c}
          donnees={series.visites}
          colonnes={[
            { cle: 'label', libelle: 'Période' },
            { cle: 'visites', libelle: 'Pages vues' },
            { cle: 'uniques', libelle: 'Visiteurs uniques' },
          ]}
        >
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={series.visites} margin={{ top: 8, right: 8, bottom: 0, left: 0 }}>
              <CartesianGrid stroke={c.grille} vertical={false} />
              <XAxis dataKey="label" {...axe} interval="preserveStartEnd" minTickGap={24} />
              <YAxis {...axe} width={44} allowDecimals={false} />
              <Tooltip content={<Infobulle c={c} />} />
              <Legend
                iconType="circle" iconSize={8}
                wrapperStyle={{ fontSize: 12, color: c.tickTexte, paddingTop: 8 }}
              />
              <Line
                type="monotone" dataKey="visites" name="Pages vues"
                stroke={c.s1} strokeWidth={2} dot={false}
                activeDot={{ r: 5, strokeWidth: 2, stroke: c.fondInfobulle }}
              />
              <Line
                type="monotone" dataKey="uniques" name="Visiteurs uniques"
                stroke={c.s2} strokeWidth={2} dot={false}
                activeDot={{ r: 5, strokeWidth: 2, stroke: c.fondInfobulle }}
              />
            </LineChart>
          </ResponsiveContainer>
        </CarteGraphique>

        {/* Clients */}
        <CarteGraphique
          titre={data.clients_label}
          sousTitre={`Par ${data.granularite}`}
          c={c}
          donnees={series.clients}
          colonnes={[
            { cle: 'label', libelle: 'Période' },
            { cle: 'valeur', libelle: data.clients_label },
          ]}
        >
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={series.clients} margin={{ top: 8, right: 8, bottom: 0, left: 0 }} barGap={2}>
              <CartesianGrid stroke={c.grille} vertical={false} />
              <XAxis dataKey="label" {...axe} interval="preserveStartEnd" minTickGap={24} />
              <YAxis {...axe} width={44} allowDecimals={false} />
              <Tooltip cursor={{ fill: c.grille, fillOpacity: 0.35 }} content={<Infobulle c={c} />} />
              <Bar dataKey="valeur" name={data.clients_label} fill={c.s1} radius={[4, 4, 0, 0]} maxBarSize={28} />
            </BarChart>
          </ResponsiveContainer>
        </CarteGraphique>

        {/* Répartitions : une mesure par catégorie => une seule teinte, le libellé
            porte l'identité (jamais la couleur seule). */}
        <div className="grid md:grid-cols-2 gap-6">
          <Repartition
            titre="Commandes par statut"
            entrees={statuts}
            total={resume.commandes_total}
            c={c}
            vide="Aucune commande sur la période."
          />
          <Repartition
            titre="Méthodes de paiement"
            entrees={paiements}
            total={resume.commandes_total}
            c={c}
            vide="Aucun paiement sur la période."
          />
        </div>

        {/* Montures consultées : deux mesures d'échelles très différentes (vues vs
            ventes) — un tableau les compare honnêtement, là où un double axe
            inventerait une corrélation. */}
        <div className="grid md:grid-cols-2 gap-6">
          <div className={`${c.carte} rounded-2xl p-5`}>
            <h2 className={`font-semibold ${c.titre} mb-1`}>Montures les plus consultées</h2>
            <p className={`text-xs ${c.sousTitre} mb-4`}>Vues comparées aux ventes sur la période</p>
            {data.top_montures.length === 0 ? (
              <p className={`text-sm ${c.sousTitre}`}>Aucune consultation enregistrée.</p>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className={`text-left ${c.sousTitre} text-xs`}>
                      <th className="py-2 pr-4 font-medium">Monture</th>
                      <th className="py-2 pr-4 font-medium text-right">Vues</th>
                      <th className="py-2 font-medium text-right">Ventes</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.top_montures.map(m => (
                      <tr key={m.id}>
                        <td className={`py-1.5 pr-4 ${c.valeur}`}>
                          {m.marque} — {m.nom}
                        </td>
                        <td className={`py-1.5 pr-4 text-right tabular-nums ${c.valeur}`}>{m.vues}</td>
                        <td className={`py-1.5 text-right tabular-nums ${c.valeur}`}>{m.ventes}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          <div className={`${c.carte} rounded-2xl p-5`}>
            <h2 className={`font-semibold ${c.titre} mb-1`}>Pages les plus vues</h2>
            <p className={`text-xs ${c.sousTitre} mb-4`}>Hors back-office</p>
            {data.pages_populaires.length === 0 ? (
              <p className={`text-sm ${c.sousTitre}`}>Aucune visite enregistrée.</p>
            ) : (
              <div className="space-y-3">
                {data.pages_populaires.map(p => (
                  <div key={p.chemin}>
                    <div className="flex items-center justify-between text-sm mb-1 gap-3">
                      <span className={`${c.valeur} truncate`}>{p.chemin}</span>
                      <span className={`${c.sousTitre} tabular-nums flex-shrink-0`}>{p.vues}</span>
                    </div>
                    <div className="h-2 rounded-full overflow-hidden" style={{ background: c.grille }}>
                      <div
                        className="h-full rounded-full"
                        style={{
                          width: `${(p.vues / data.pages_populaires[0].vues) * 100}%`,
                          background: c.s1,
                        }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
