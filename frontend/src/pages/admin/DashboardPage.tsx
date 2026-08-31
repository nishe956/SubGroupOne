import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { UsersRound, Stethoscope, ShoppingCart, Glasses, Banknote, ArrowUpRight } from 'lucide-react';
import api, { formatCFA, listeDepuis } from '@/lib/api';
import { DashboardStats } from '@/types';
import {
  Carte, EnTeteCarte, CarteStat, Badge, statutCommande, Tableau, Colonne,
  EnTetePage, Avatar, CourbeRevenus,
} from '@/components/admin';

/** Commande telle que renvoyée par `/commandes/` (vue liste). */
interface LigneCommande {
  id: number;
  client_nom?: string;
  monture_detail?: { nom?: string; marque?: string } | null;
  prix_total: number | string;
  statut: string;
  date_commande: string;
}

export default function AdminDashboard() {
  const { data: stats, isLoading } = useQuery<DashboardStats>({
    queryKey: ['admin-stats'],
    queryFn: () => api.get('/stats/dashboard/').then(r => r.data),
  });

  const { data: commandes, isLoading: chargementCommandes } = useQuery<LigneCommande[]>({
    queryKey: ['admin-dernieres-commandes'],
    queryFn: () => api.get('/commandes/').then(r => listeDepuis<LigneCommande>(r.data)),
  });

  if (isLoading) {
    return (
      <div className="flex justify-center py-24">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-accent-500" />
      </div>
    );
  }

  const ventesMensuelles = stats?.ventes_mensuelles ?? [];

  // Évolution du chiffre d'affaires : dernier mois clos face au précédent.
  // Sans deux mois comparables, on n'affiche aucun pourcentage plutôt qu'un
  // « +100 % » qui ne voudrait rien dire.
  const derniers = ventesMensuelles.slice(-2);
  const evolutionCA =
    derniers.length === 2 && derniers[0].total > 0
      ? Math.round(((derniers[1].total - derniers[0].total) / derniers[0].total) * 100)
      : null;

  // Les compteurs passent par la locale : « 12 540 » se lit d'un coup d'œil,
  // « 12540 » demande de compter les chiffres.
  const nombre = (valeur: number | undefined) => (valeur ?? 0).toLocaleString('fr-FR');

  const tuiles = [
    {
      libelle: 'Clients', valeur: nombre(stats?.total_clients),
      icone: UsersRound, teinte: 'bleu' as const,
    },
    {
      libelle: 'Opticiens', valeur: nombre(stats?.total_opticiens),
      icone: Stethoscope, teinte: 'violet' as const,
    },
    {
      libelle: 'Commandes', valeur: nombre(stats?.total_commandes),
      icone: ShoppingCart, teinte: 'accent' as const,
      detail: `${nombre(stats?.commandes_mois)} ce mois-ci`,
    },
    {
      libelle: 'Montures', valeur: nombre(stats?.total_montures),
      icone: Glasses, teinte: 'emeraude' as const,
      detail: `${nombre(stats?.montures_epuisees)} en rupture`,
    },
    {
      libelle: "Chiffre d'affaires", valeur: formatCFA(stats?.chiffre_affaires ?? 0),
      icone: Banknote, teinte: 'ambre' as const,
      variation: evolutionCA,
      detail: `${formatCFA(stats?.revenus_mois ?? 0)} ce mois-ci`,
    },
  ];

  const revenus = stats?.revenus_par_boutique ?? [];
  const caReseau = revenus.reduce((total, b) => total + b.ca_total, 0);

  const colonnesBoutiques: Colonne<(typeof revenus)[number]>[] = [
    {
      cle: 'boutique', libelle: 'Boutique',
      rendu: b => (
        <div className="flex items-center gap-3">
          <Avatar nom={b.boutique} taille="sm" />
          <span className="font-medium text-gray-900">{b.boutique}</span>
        </div>
      ),
    },
    { cle: 'ventes', libelle: 'Ventes', align: 'right', rendu: b => <span className="text-gray-500 tabular-nums">{b.nb_ventes}</span> },
    { cle: 'mois', libelle: 'CA du mois', align: 'right', rendu: b => <span className="text-gray-600 tabular-nums">{formatCFA(b.ca_mois)}</span> },
    { cle: 'total', libelle: 'CA total', align: 'right', rendu: b => <span className="font-semibold text-gray-900 tabular-nums">{formatCFA(b.ca_total)}</span> },
    {
      cle: 'part', libelle: 'Part du réseau', align: 'right', className: 'w-40',
      // Repère d'un coup d'œil la boutique qui porte l'essentiel du chiffre.
      rendu: b => {
        const part = caReseau > 0 ? (b.ca_total / caReseau) * 100 : 0;
        return (
          <div className="flex items-center gap-2 justify-end">
            <div className="h-1.5 w-20 bg-gray-100 rounded-full overflow-hidden">
              <div className="h-full bg-accent-500 rounded-full" style={{ width: `${part}%` }} />
            </div>
            <span className="text-xs text-gray-500 w-9 text-right tabular-nums">{part.toFixed(0)} %</span>
          </div>
        );
      },
    },
  ];

  const colonnesCommandes: Colonne<LigneCommande>[] = [
    {
      cle: 'client', libelle: 'Client',
      rendu: c => (
        <div className="flex items-center gap-3">
          <Avatar nom={c.client_nom ?? '?'} taille="sm" />
          <span className="font-medium text-gray-900">{c.client_nom ?? 'Client supprimé'}</span>
        </div>
      ),
    },
    {
      cle: 'produit', libelle: 'Monture',
      rendu: c => (
        <span className="text-gray-500">
          {c.monture_detail ? `${c.monture_detail.marque ?? ''} ${c.monture_detail.nom ?? ''}`.trim() : '—'}
        </span>
      ),
    },
    { cle: 'montant', libelle: 'Montant', align: 'right', rendu: c => <span className="font-semibold text-gray-900 tabular-nums">{formatCFA(c.prix_total)}</span> },
    {
      cle: 'statut', libelle: 'Statut',
      rendu: c => { const s = statutCommande(c.statut); return <Badge ton={s.ton}>{s.libelle}</Badge>; },
    },
    {
      cle: 'date', libelle: 'Date', align: 'right',
      rendu: c => <span className="text-gray-500 tabular-nums">{new Date(c.date_commande).toLocaleDateString('fr-FR')}</span>,
    },
  ];

  const statuts = Object.entries(stats?.commandes_par_statut ?? {});
  const totalStatuts = statuts.reduce((somme, [, nb]) => somme + nb, 0);
  // Le backend écrit « livree » ou « livrée » selon l'ancienneté des données.
  const nbLivrees = (stats?.commandes_par_statut?.livree ?? 0) + (stats?.commandes_par_statut?.['livrée'] ?? 0);
  const tauxLivraison = totalStatuts > 0 ? Math.round((nbLivrees / totalStatuts) * 100) : null;

  return (
    <div>
      <EnTetePage titre="Vue d'ensemble" sousTitre="Activité de l'ensemble du réseau Lunette Pro">
        <Link
          to="/admin/statistiques"
          className="inline-flex items-center gap-1.5 rounded-xl bg-accent-500 hover:bg-accent-600 text-white text-sm font-medium px-4 py-2.5 transition-colors"
        >
          Statistiques détaillées <ArrowUpRight className="w-4 h-4" />
        </Link>
      </EnTetePage>

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-5 gap-4 mb-6">
        {tuiles.map(t => <CarteStat key={t.libelle} {...t} />)}
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-4 mb-6">
        <div className="xl:col-span-2">
          {ventesMensuelles.length > 0 ? (
            <CourbeRevenus points={ventesMensuelles} />
          ) : (
            <Carte className="h-full flex flex-col items-center justify-center text-center py-16">
              <Banknote className="w-9 h-9 text-gray-300 mb-3" strokeWidth={1.5} />
              <div className="font-medium text-gray-700">Aucune vente livrée</div>
              <p className="text-sm text-gray-400 mt-1">La courbe des revenus apparaîtra dès la première commande livrée.</p>
            </Carte>
          )}
        </div>

        <Carte className="flex flex-col">
          <EnTeteCarte titre="Commandes par statut" sousTitre={`${nombre(totalStatuts)} commande${totalStatuts > 1 ? 's' : ''} au total`} />
          {statuts.length === 0 ? (
            <p className="text-sm text-gray-400">Aucune commande enregistrée.</p>
          ) : (
            <ul className="space-y-3.5 flex-1">
              {statuts.map(([statut, nb]) => {
                const s = statutCommande(statut);
                const part = totalStatuts > 0 ? (nb / totalStatuts) * 100 : 0;
                return (
                  <li key={statut}>
                    <div className="flex items-center justify-between mb-1.5">
                      <Badge ton={s.ton}>{s.libelle}</Badge>
                      <span className="text-sm font-semibold text-gray-900 tabular-nums">{nombre(nb)}</span>
                    </div>
                    <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
                      <div className="h-full bg-gray-300 rounded-full" style={{ width: `${part}%` }} />
                    </div>
                  </li>
                );
              })}
            </ul>
          )}
          {tauxLivraison !== null && (
            <div className="mt-5 pt-4 border-t border-gray-100 flex items-baseline justify-between">
              <span className="text-sm text-gray-500">Part des commandes livrées</span>
              <span className="text-lg font-bold text-gray-900 tabular-nums">{tauxLivraison} %</span>
            </div>
          )}
        </Carte>
      </div>

      <section className="mb-6">
        <EnTeteCarte
          titre="Revenus par boutique"
          sousTitre={`${revenus.length} boutique${revenus.length > 1 ? 's' : ''} · ${formatCFA(caReseau)} sur le réseau`}
        />
        <Tableau
          colonnes={colonnesBoutiques}
          lignes={revenus}
          cleLigne={b => b.opticien_id ?? b.boutique}
          parPage={6}
          vide={{ titre: 'Aucun revenu enregistré', texte: 'Les ventes des boutiques apparaîtront ici.' }}
        />
      </section>

      <section>
        <EnTeteCarte titre="Dernières commandes" sousTitre="Toutes boutiques confondues" />
        <Tableau
          colonnes={colonnesCommandes}
          lignes={commandes ?? []}
          cleLigne={c => c.id}
          chargement={chargementCommandes}
          parPage={6}
          vide={{ titre: 'Aucune commande', texte: "Les commandes passées sur la plateforme s'afficheront ici." }}
        />
      </section>
    </div>
  );
}
