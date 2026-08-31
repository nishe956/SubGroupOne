"""Tests de sécurité — logique métier et flux financiers (V05, V06, V07, V18)."""
from decimal import Decimal

from django.urls import Resolver404, resolve
from famille.models import GroupeFamille

from commandes.models import Commande
from commandes.tarifs import calculer_total

from .base import BaseSecurite


class TestPrixCommande(BaseSecurite):
    """Le prix ne doit jamais dépendre d'une valeur envoyée par le client (V06)."""

    def _passer_commande(self, **extra):
        payload = {'monture': self.monture_a.pk, 'type_commande': 'style'}
        payload.update(extra)
        return self.client.post('/api/commandes/passer/', payload, format='json')

    def test_rabais_famille_envoye_par_le_client_est_ignore(self):
        self.connecter(self.client_1)
        reponse = self._passer_commande(rabais_famille=1)
        self.assertEqual(reponse.status_code, 201)
        commande = Commande.objects.get(pk=reponse.data['id'])
        self.assertEqual(commande.prix_total, Decimal('50000.00'))

    def test_prix_verres_envoye_par_le_client_est_ignore(self):
        self.connecter(self.client_1)
        reponse = self._passer_commande(prix_verres='-49000')
        self.assertEqual(reponse.status_code, 201)
        commande = Commande.objects.get(pk=reponse.data['id'])
        self.assertEqual(commande.prix_total, Decimal('50000.00'))

    def test_prix_total_envoye_par_le_client_est_ignore(self):
        self.connecter(self.client_1)
        reponse = self._passer_commande(prix_total='1')
        self.assertEqual(reponse.status_code, 201)
        commande = Commande.objects.get(pk=reponse.data['id'])
        self.assertEqual(commande.prix_total, Decimal('50000.00'))

    def test_type_de_verre_inconnu_refuse(self):
        """Accepter un identifiant inconnu reviendrait à facturer les verres 0."""
        self.connecter(self.client_1)
        reponse = self._passer_commande(type_verre='verres_gratuits')
        self.assertEqual(reponse.status_code, 400)

    def test_rabais_famille_reel_applique_depuis_la_base(self):
        groupe = GroupeFamille.objects.create(nom='Famille', chef=self.client_1)
        groupe.membres.add(self.client_1, self.client_2)  # 2 membres => 5 %

        total, verres, taux = calculer_total(self.monture_a, self.client_1)
        self.assertEqual(taux, Decimal('0.05'))
        self.assertEqual(total, Decimal('47500.00'))

    def test_prix_des_verres_calcule_serveur(self):
        total, verres, _ = calculer_total(
            self.monture_a, self.client_1,
            type_verre='progressif', options=['anti_reflets', 'uv'])
        # 55000 (progressif) + 8000 (anti-reflets) + 4000 (UV)
        self.assertEqual(verres, Decimal('67000.00'))
        self.assertEqual(total, Decimal('117000.00'))

    def test_option_dupliquee_facturee_une_seule_fois(self):
        _, verres, _ = calculer_total(
            self.monture_a, self.client_1,
            type_verre='unifocal_simple', options=['uv', 'uv', 'uv'])
        self.assertEqual(verres, Decimal('19000.00'))

    def test_ordonnance_dun_tiers_refusee(self):
        self.connecter(self.client_1)
        reponse = self.client.post('/api/commandes/passer/', {
            'monture': self.monture_a.pk, 'type_commande': 'vue',
            'ordonnance': self.ordonnance_2.pk,
        }, format='json')
        self.assertEqual(reponse.status_code, 400)


class TestPaiement(BaseSecurite):

    def test_endpoint_de_confirmation_supprime(self):
        """V05 : le client validait lui-même son paiement."""
        with self.assertRaises(Resolver404):
            resolve(f'/api/commandes/{self.commande_1.pk}/paiement/confirmer/')

    def test_confirmation_paiement_renvoie_404(self):
        self.connecter(self.client_1)
        reponse = self.client.post(
            f'/api/commandes/{self.commande_1.pk}/paiement/confirmer/',
            {'reference': 'peu-importe'}, format='json')
        self.assertEqual(reponse.status_code, 404)
        self.commande_1.refresh_from_db()
        self.assertEqual(self.commande_1.statut, 'validee')

    def test_initier_paiement_ne_change_pas_le_statut(self):
        commande = Commande.objects.create(
            client=self.client_1, monture=self.monture_a, opticien=self.opticien_a,
            prix_total=Decimal('50000'), statut='en_attente')
        self.connecter(self.client_1)
        reponse = self.client.post(
            f'/api/commandes/{commande.pk}/paiement/',
            {'methode': 'orange_money'}, format='json')
        self.assertEqual(reponse.status_code, 200)
        commande.refresh_from_db()
        self.assertEqual(commande.statut, 'en_attente')


class TestMachineAEtats(BaseSecurite):

    def test_commande_livree_ne_revient_pas_a_validee(self):
        self.commande_1.statut = 'livree'
        self.commande_1.save(update_fields=['statut'])
        self.connecter(self.opticien_a)
        reponse = self.client.post(
            f'/api/commandes/{self.commande_1.pk}/gerer/',
            {'statut': 'validee'}, format='json')
        self.assertEqual(reponse.status_code, 400)

    def test_transition_valide_acceptee(self):
        self.connecter(self.opticien_a)
        reponse = self.client.post(
            f'/api/commandes/{self.commande_1.pk}/gerer/',
            {'statut': 'en_preparation'}, format='json')
        self.assertEqual(reponse.status_code, 200)


class TestRemboursement(BaseSecurite):
    """V07 : fraude à l'assurance par demande arbitraire."""

    def test_demande_sur_la_commande_dun_tiers_refusee(self):
        self.connecter(self.client_2)
        reponse = self.client.post('/api/assurance/demandes/', {
            'commande': self.commande_1.pk,
            'compagnie': self.compagnie.pk,
            'montant_total': '5000000.00',
        }, format='json')
        self.assertEqual(reponse.status_code, 400)

    def test_montant_ignore_et_repris_de_la_commande(self):
        self.connecter(self.client_1)
        reponse = self.client.post('/api/assurance/demandes/', {
            'commande': self.commande_1.pk,
            'compagnie': self.compagnie.pk,
            'montant_total': '5000000.00',
        }, format='json')
        self.assertEqual(reponse.status_code, 201)
        self.assertEqual(Decimal(reponse.data['montant_total']), Decimal('50000.00'))
        # 80 % de 50 000, pas 80 % du montant réclamé.
        self.assertEqual(Decimal(reponse.data['montant_rembourse']), Decimal('40000.00'))

    def test_une_seule_demande_par_commande(self):
        self.connecter(self.client_1)
        payload = {'commande': self.commande_1.pk, 'compagnie': self.compagnie.pk}
        self.assertEqual(
            self.client.post('/api/assurance/demandes/', payload, format='json').status_code, 201)
        self.assertEqual(
            self.client.post('/api/assurance/demandes/', payload, format='json').status_code, 400)

    def test_commande_non_eligible_refusee(self):
        commande = Commande.objects.create(
            client=self.client_1, monture=self.monture_a, opticien=self.opticien_a,
            prix_total=Decimal('50000'), statut='en_attente')
        self.connecter(self.client_1)
        reponse = self.client.post('/api/assurance/demandes/', {
            'commande': commande.pk, 'compagnie': self.compagnie.pk,
        }, format='json')
        self.assertEqual(reponse.status_code, 400)

    def test_remboursement_plafonne_au_montant_paye(self):
        from assurance.models import CompagnieAssurance, DemandeRemboursement

        genereuse = CompagnieAssurance.objects.create(
            nom='Trop Genereuse', code='TG', taux_prise_charge=Decimal('150.00'))
        demande = DemandeRemboursement(
            commande=self.commande_1, compagnie=genereuse,
            client=self.client_1, montant_total=Decimal('50000'))
        demande.calculer_montants()
        self.assertEqual(demande.montant_rembourse, Decimal('50000.00'))
        self.assertEqual(demande.montant_patient, Decimal('0.00'))


class TestStock(BaseSecurite):
    """V18 : décrément non atomique du stock."""

    def test_stock_decremente_a_la_commande(self):
        self.connecter(self.client_1)
        self.client.post('/api/commandes/passer/', {
            'monture': self.monture_a.pk, 'type_commande': 'style',
        }, format='json')
        self.monture_a.refresh_from_db()
        self.assertEqual(self.monture_a.stock, 4)

    def test_commande_refusee_en_rupture(self):
        self.monture_a.stock = 0
        self.monture_a.save(update_fields=['stock'])
        self.connecter(self.client_1)
        reponse = self.client.post('/api/commandes/passer/', {
            'monture': self.monture_a.pk, 'type_commande': 'style',
        }, format='json')
        self.assertEqual(reponse.status_code, 400)

    def test_stock_jamais_negatif_meme_sous_charge(self):
        """Le décrément conditionnel doit refuser dès que le stock atteint 0."""
        self.monture_a.stock = 2
        self.monture_a.save(update_fields=['stock'])
        self.connecter(self.client_1)
        codes = [
            self.client.post('/api/commandes/passer/', {
                'monture': self.monture_a.pk, 'type_commande': 'style',
            }, format='json').status_code
            for _ in range(4)
        ]
        self.monture_a.refresh_from_db()
        self.assertEqual(self.monture_a.stock, 0)
        self.assertEqual(codes.count(201), 2)
        self.assertEqual(codes.count(400), 2)
