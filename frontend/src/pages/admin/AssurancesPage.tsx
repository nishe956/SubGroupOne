import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, X, ShieldCheck } from 'lucide-react';
import api, { listeDepuis, formatCFA } from '@/lib/api';
import { CompagnieAssurance } from '@/types';
import toast from 'react-hot-toast';
import { Carte, EnTeteCarte, Badge, Tableau, Colonne, EnTetePage } from '@/components/admin';

export default function AdminAssurances() {
  const qc = useQueryClient();
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ nom: '', code: '', taux_prise_charge: '', plafond_annuel: '' });

  const { data, isLoading } = useQuery({
    queryKey: ['compagnies-assurance'],
    queryFn: () => api.get('/assurance/compagnies/').then(r => listeDepuis<CompagnieAssurance>(r.data)),
  });

  const assurances: CompagnieAssurance[] = data ?? [];

  const createMutation = useMutation({
    mutationFn: () => api.post('/assurance/compagnies/', {
      ...form,
      taux_prise_charge: Number(form.taux_prise_charge),
      plafond_annuel: form.plafond_annuel ? Number(form.plafond_annuel) : null,
    }),
    onSuccess: () => {
      toast.success('Assurance créée');
      qc.invalidateQueries({ queryKey: ['compagnies-assurance'] });
      setShowForm(false);
      setForm({ nom: '', code: '', taux_prise_charge: '', plafond_annuel: '' });
    },
    onError: () => toast.error('Erreur lors de la création'),
  });

  const colonnes: Colonne<CompagnieAssurance>[] = [
    {
      cle: 'nom', libelle: 'Compagnie',
      rendu: a => (
        <div className="flex items-center gap-3">
          <span className="w-9 h-9 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center flex-shrink-0">
            <ShieldCheck className="w-4 h-4" strokeWidth={1.75} />
          </span>
          <span className="font-medium text-gray-900">{a.nom}</span>
        </div>
      ),
    },
    { cle: 'code', libelle: 'Code', rendu: a => <Badge ton="neutre">{a.code}</Badge> },
    {
      cle: 'taux', libelle: 'Prise en charge', align: 'right',
      rendu: a => <span className="font-semibold text-gray-900 tabular-nums">{a.taux_prise_charge} %</span>,
    },
    {
      cle: 'plafond', libelle: 'Plafond annuel', align: 'right',
      rendu: a => (
        <span className="text-gray-500 tabular-nums">
          {a.plafond_annuel ? formatCFA(a.plafond_annuel) : 'Aucun'}
        </span>
      ),
    },
    {
      cle: 'statut', libelle: 'Statut',
      rendu: a => <Badge ton={a.active ? 'succes' : 'neutre'}>{a.active ? 'Active' : 'Inactive'}</Badge>,
    },
  ];

  const formulaireComplet = form.nom && form.code && form.taux_prise_charge;

  return (
    <div>
      <EnTetePage
        titre="Assurances"
        sousTitre={`${assurances.length} compagnie${assurances.length > 1 ? 's' : ''} partenaire${assurances.length > 1 ? 's' : ''}`}
      >
        <button
          onClick={() => setShowForm(o => !o)}
          className={`inline-flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-medium transition-colors ${
            showForm
              ? 'border border-gray-200 text-gray-600 hover:bg-gray-50'
              : 'bg-accent-500 hover:bg-accent-600 text-white'
          }`}
        >
          {showForm ? <X className="w-4 h-4" /> : <Plus className="w-4 h-4" />}
          {showForm ? 'Annuler' : 'Ajouter une compagnie'}
        </button>
      </EnTetePage>

      {showForm && (
        <Carte className="mb-4">
          <EnTeteCarte titre="Nouvelle compagnie" sousTitre="Le code sert d'identifiant court dans les commandes." />
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
            <div>
              <label htmlFor="assurance-nom" className="label">Nom</label>
              <input
                id="assurance-nom"
                value={form.nom}
                onChange={e => setForm(f => ({ ...f, nom: e.target.value }))}
                className="champ-admin"
                placeholder="MGEN"
              />
            </div>
            <div>
              <label htmlFor="assurance-code" className="label">Code</label>
              <input
                id="assurance-code"
                value={form.code}
                onChange={e => setForm(f => ({ ...f, code: e.target.value.toUpperCase() }))}
                className="champ-admin"
                placeholder="MGEN"
              />
            </div>
            <div>
              <label htmlFor="assurance-taux" className="label">Taux de remboursement (%)</label>
              <input
                id="assurance-taux"
                type="number"
                value={form.taux_prise_charge}
                onChange={e => setForm(f => ({ ...f, taux_prise_charge: e.target.value }))}
                className="champ-admin"
                placeholder="70"
              />
            </div>
            <div>
              <label htmlFor="assurance-plafond" className="label">Plafond annuel (optionnel)</label>
              <input
                id="assurance-plafond"
                type="number"
                value={form.plafond_annuel}
                onChange={e => setForm(f => ({ ...f, plafond_annuel: e.target.value }))}
                className="champ-admin"
                placeholder="300000"
              />
            </div>
          </div>
          <button
            onClick={() => createMutation.mutate()}
            disabled={!formulaireComplet || createMutation.isPending}
            className="bg-accent-500 hover:bg-accent-600 text-white px-5 py-2.5 rounded-xl text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {createMutation.isPending ? 'Création...' : "Créer l'assurance"}
          </button>
        </Carte>
      )}

      <Tableau
        colonnes={colonnes}
        lignes={assurances}
        cleLigne={a => a.id}
        chargement={isLoading}
        parPage={10}
        vide={{ titre: 'Aucune compagnie', texte: 'Ajoutez une compagnie pour activer la prise en charge.' }}
      />
    </div>
  );
}
