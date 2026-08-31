"""Tests de sécurité — cloisonnement et contrôle d'accès (V04, V10, V11, V12, V20)."""
from decimal import Decimal

from django.urls import NoReverseMatch, reverse

from commandes.models import Commande
from montures.models import Monture

from .base import BaseSecurite


class TestOrdonnancesCloisonnees(BaseSecurite):
    """Les ordonnances sont des données de santé : accès strictement nécessaire."""

    def test_client_ne_voit_que_ses_ordonnances(self):
        self.connecter(self.client_1)
        reponse = self.client.get('/api/ordonnances/')
        ids = [o['id'] for o in reponse.data['results']]
        self.assertIn(self.ordonnance_1.pk, ids)
        self.assertNotIn(self.ordonnance_2.pk, ids)

    def test_client_ne_peut_pas_lire_lordonnance_dun_autre(self):
        self.connecter(self.client_1)
        reponse = self.client.get(f'/api/ordonnances/{self.ordonnance_2.pk}/')
        self.assertEqual(reponse.status_code, 404)

    def test_opticien_sans_commande_liee_ne_voit_aucune_ordonnance(self):
        """Auparavant, tout opticien lisait l'intégralité des ordonnances (V10)."""
        self.connecter(self.opticien_b)
        reponse = self.client.get('/api/ordonnances/')
        self.assertEqual(reponse.data['count'], 0)

    def test_opticien_voit_lordonnance_dune_commande_qui_lui_revient(self):
        self.commande_1.ordonnance = self.ordonnance_1
        self.commande_1.save(update_fields=['ordonnance'])
        self.connecter(self.opticien_a)
        reponse = self.client.get('/api/ordonnances/')
        ids = [o['id'] for o in reponse.data['results']]
        self.assertIn(self.ordonnance_1.pk, ids)
        self.assertNotIn(self.ordonnance_2.pk, ids)

    def test_opticien_ne_peut_pas_supprimer_une_ordonnance(self):
        self.commande_1.ordonnance = self.ordonnance_1
        self.commande_1.save(update_fields=['ordonnance'])
        self.connecter(self.opticien_a)
        reponse = self.client.delete(f'/api/ordonnances/{self.ordonnance_1.pk}/')
        self.assertEqual(reponse.status_code, 403)

    def test_telechargement_image_refuse_pour_un_tiers(self):
        self.connecter(self.client_2)
        reponse = self.client.get(f'/api/ordonnances/{self.ordonnance_1.pk}/image/')
        self.assertEqual(reponse.status_code, 404)

    def test_serializer_nexpose_pas_lurl_de_stockage(self):
        """L'URL doit pointer vers la vue authentifiée, jamais vers le bucket."""
        self.connecter(self.client_1)
        reponse = self.client.get(f'/api/ordonnances/{self.ordonnance_1.pk}/')
        self.assertNotIn('r2.dev', str(reponse.data))
        self.assertNotIn('/media/ordonnances/', str(reponse.data))


class TestMediaPrive(BaseSecurite):
    """La route /media/ ne doit plus exposer les documents médicaux (V03, V04)."""

    def test_route_media_absente_en_configuration_bucket(self):
        from django.conf import settings
        from django.urls import get_resolver

        motifs = [str(p.pattern) for p in get_resolver().url_patterns]
        if settings.AWS_STORAGE_BUCKET_NAME or not settings.DEBUG:
            self.assertFalse(
                any('media' in m for m in motifs),
                "La route /media/ ne doit pas être montée hors développement local.",
            )

    def test_normalisation_du_chemin_bloque_les_contournements(self):
        """`//`, `./` et `../` échappaient au filtre par préfixe (V04)."""
        import posixpath

        from config.urls import MEDIA_PRIVE

        contournements = [
            '/ordonnances/x.jpg',
            './ordonnances/x.jpg',
            'a/../ordonnances/x.jpg',
            'a/b/../../ordonnances/x.jpg',
        ]
        for brut in contournements:
            with self.subTest(chemin=brut):
                normalise = posixpath.normpath('/' + brut).lstrip('/')
                self.assertTrue(
                    any(normalise.startswith(p) for p in MEDIA_PRIVE),
                    f"{brut!r} doit être reconnu comme privé après normalisation.",
                )


class TestCloisonnementOpticiens(BaseSecurite):

    def test_opticien_ne_peut_pas_ajuster_le_stock_dun_concurrent(self):
        """V11 : sabotage commercial entre boutiques."""
        self.connecter(self.opticien_b)
        reponse = self.client.post('/api/stock/ajuster/', {
            'monture_id': self.monture_a.pk, 'type': 'ajustement', 'quantite': 0,
        }, format='json')
        self.assertEqual(reponse.status_code, 404)
        self.monture_a.refresh_from_db()
        self.assertEqual(self.monture_a.stock, 5)

    def test_opticien_ne_peut_pas_modifier_le_stock_dun_concurrent(self):
        self.connecter(self.opticien_b)
        reponse = self.client.patch(
            f'/api/montures/{self.monture_a.pk}/stock/', {'stock': 0}, format='json')
        self.assertEqual(reponse.status_code, 403)

    def test_opticien_ne_peut_pas_supprimer_limage_dun_concurrent(self):
        self.connecter(self.opticien_b)
        reponse = self.client.delete(f'/api/montures/{self.monture_a.pk}/images/principale/')
        self.assertEqual(reponse.status_code, 403)

    def test_stock_negatif_refuse(self):
        self.connecter(self.opticien_a)
        reponse = self.client.patch(
            f'/api/montures/{self.monture_a.pk}/stock/', {'stock': -10}, format='json')
        self.assertEqual(reponse.status_code, 400)

    def test_stock_non_numerique_ne_provoque_pas_de_500(self):
        """V28 : `int()` sur entrée utilisateur non gardée."""
        self.connecter(self.opticien_a)
        reponse = self.client.patch(
            f'/api/montures/{self.monture_a.pk}/stock/', {'stock': 'abc'}, format='json')
        self.assertEqual(reponse.status_code, 400)

    def test_opticien_ne_voit_que_son_propre_stock(self):
        self.connecter(self.opticien_b)
        reponse = self.client.get('/api/stock/overview/')
        self.assertEqual(reponse.data['total_montures'], 1)

    def test_opticien_ne_voit_pas_les_commandes_dun_concurrent(self):
        self.connecter(self.opticien_b)
        reponse = self.client.get(f'/api/commandes/{self.commande_1.pk}/')
        self.assertEqual(reponse.status_code, 404)

    def test_historique_sms_cloisonne(self):
        from marketing.models import HistoriqueSMS

        HistoriqueSMS.objects.create(
            destinataire=self.client_1, telephone='+22670000000',
            message='secret A', envoye_par=self.opticien_a)
        self.connecter(self.opticien_b)
        reponse = self.client.get('/api/marketing/sms/historique/')
        self.assertEqual(reponse.data['count'], 0)

    def test_opticien_ne_peut_pas_envoyer_de_sms_a_un_tiers(self):
        """V27 : `User.objects.get(pk=pk)` sans contrôle de rattachement."""
        self.connecter(self.opticien_b)
        reponse = self.client.post(
            f'/api/marketing/souhaits/{self.admin.pk}/', {}, format='json')
        self.assertEqual(reponse.status_code, 404)


class TestAssurance(BaseSecurite):

    def test_opticien_ne_peut_pas_creer_de_compagnie(self):
        """V12 : le taux de prise en charge pilote les montants remboursés."""
        self.connecter(self.opticien_a)
        reponse = self.client.post('/api/assurance/compagnies/', {
            'nom': 'Fausse Assur', 'code': 'FA', 'taux_prise_charge': '100.00',
        }, format='json')
        self.assertEqual(reponse.status_code, 403)

    def test_opticien_ne_peut_pas_modifier_un_taux(self):
        self.connecter(self.opticien_a)
        reponse = self.client.patch(
            f'/api/assurance/compagnies/{self.compagnie.pk}/',
            {'taux_prise_charge': '100.00'}, format='json')
        self.assertEqual(reponse.status_code, 403)


class TestPublications(BaseSecurite):

    def test_client_ne_peut_pas_publier(self):
        """V20 : n'importe quel client publiait sur le site public."""
        self.connecter(self.client_1)
        reponse = self.client.post('/api/publications/creer/', {
            'titre': 'Spam', 'contenu': 'Contenu indésirable',
        }, format='json')
        self.assertEqual(reponse.status_code, 403)

    def test_publication_dopticien_reste_un_brouillon(self):
        self.connecter(self.opticien_a)
        reponse = self.client.post('/api/publications/creer/', {
            'titre': 'Conseil', 'contenu': 'Texte',
        }, format='json')
        self.assertEqual(reponse.status_code, 201)
        self.assertFalse(reponse.data['publie'])

    def test_like_sur_publication_inexistante_renvoie_404(self):
        """V28 : levait une 500 auparavant."""
        self.connecter(self.client_1)
        reponse = self.client.post('/api/publications/999999/liker/', {}, format='json')
        self.assertEqual(reponse.status_code, 404)


class TestRevenusParBoutique(BaseSecurite):
    """Le détail du CA par boutique est une information commerciale sensible :
    il ne doit remonter que pour l'administrateur."""

    def setUp(self):
        super().setUp()
        self.commande_1.statut = 'livree'
        self.commande_1.save(update_fields=['statut'])

    def test_admin_voit_le_detail_par_boutique(self):
        self.connecter(self.admin)
        reponse = self.client.get('/api/stats/dashboard/')
        self.assertEqual(reponse.status_code, 200)
        lignes = reponse.data['revenus_par_boutique']
        self.assertEqual(len(lignes), 1)
        self.assertEqual(float(lignes[0]['ca_total']), 50000.0)
        self.assertEqual(lignes[0]['nb_ventes'], 1)

    def test_opticien_ne_voit_aucun_detail_par_boutique(self):
        """Sinon chaque opticien connaîtrait le chiffre d'affaires de ses concurrents."""
        self.connecter(self.opticien_a)
        reponse = self.client.get('/api/stats/dashboard/')
        self.assertEqual(reponse.status_code, 200)
        self.assertEqual(reponse.data['revenus_par_boutique'], [])

    def test_nom_de_boutique_utilise_quand_il_existe(self):
        from boutique.models import BoutiqueOpticien

        BoutiqueOpticien.objects.create(
            opticien=self.opticien_a, nom='Optique du Centre', adresse='Ouaga')
        self.connecter(self.admin)
        reponse = self.client.get('/api/stats/dashboard/')
        self.assertEqual(reponse.data['revenus_par_boutique'][0]['boutique'], 'Optique du Centre')

    def test_repli_sur_le_nom_dutilisateur_sans_boutique(self):
        self.connecter(self.admin)
        reponse = self.client.get('/api/stats/dashboard/')
        self.assertEqual(reponse.data['revenus_par_boutique'][0]['boutique'], 'optic_a')

    def test_seules_les_ventes_realisees_sont_comptees(self):
        """Une commande en attente ne doit pas gonfler le chiffre d'affaires."""
        from decimal import Decimal

        Commande.objects.create(
            client=self.client_2, monture=self.monture_a, opticien=self.opticien_a,
            prix_total=Decimal('999999'), statut='en_attente')
        self.connecter(self.admin)
        reponse = self.client.get('/api/stats/dashboard/')
        self.assertEqual(float(reponse.data['revenus_par_boutique'][0]['ca_total']), 50000.0)


class TestValidationOpticien(BaseSecurite):
    """Le parcours d'inscription opticien doit passer par une décision explicite
    de l'administrateur avant toute visibilité ou tout accès."""

    PAYLOAD = {
        'username': 'nouvel_optic', 'email': 'no@test.bf',
        'password': 'Correct-Horse-Battery-2026', 'role': 'opticien',
        'boutique_nom': 'Optique Nouvelle',
    }

    def _inscrire(self):
        reponse = self.client.post('/api/users/register/', self.PAYLOAD, format='json')
        self.assertEqual(reponse.status_code, 201, reponse.data)
        from django.contrib.auth import get_user_model
        return get_user_model().objects.get(username='nouvel_optic')

    def test_compte_cree_en_attente(self):
        user = self._inscrire()
        self.assertEqual(user.statut_validation, 'en_attente')

    def test_connexion_refusee_avant_validation(self):
        self._inscrire()
        reponse = self.client.post('/api/users/login/', {
            'username': 'nouvel_optic', 'password': self.PAYLOAD['password'],
        }, format='json')
        self.assertEqual(reponse.status_code, 403)
        self.assertNotIn('access', reponse.data)

    def test_boutique_invisible_au_public_avant_validation(self):
        self._inscrire()
        self.deconnecter()
        reponse = self.client.get('/api/boutiques/')
        noms = [b['nom'] for b in reponse.data['results']]
        self.assertNotIn('Optique Nouvelle', noms)

    def test_absent_de_la_liste_des_utilisateurs_avant_decision(self):
        """La demande n'a pas sa place parmi les comptes validés."""
        self._inscrire()
        self.connecter(self.admin)
        reponse = self.client.get('/api/users/liste/')
        noms = [u['username'] for u in reponse.data['results']]
        self.assertNotIn('nouvel_optic', noms)

    def test_present_dans_les_demandes_en_attente(self):
        self._inscrire()
        self.connecter(self.admin)
        reponse = self.client.get('/api/users/opticiens/en-attente/')
        noms = [u['username'] for u in reponse.data['results']]
        self.assertIn('nouvel_optic', noms)

    def test_administrateur_notifie_par_email(self):
        from django.core import mail

        mail.outbox = []
        self._inscrire()
        self.assertEqual(len(mail.outbox), 1)
        self.assertIn(self.admin.email, mail.outbox[0].to)
        self.assertIn('opticien', mail.outbox[0].subject.lower())

    def test_apres_approbation_tout_devient_visible(self):
        user = self._inscrire()
        self.connecter(self.admin)
        reponse = self.client.post(
            f'/api/users/opticiens/{user.pk}/valider/', {'action': 'approuver'}, format='json')
        self.assertEqual(reponse.status_code, 200)

        # Présent dans la liste des comptes validés
        noms = [u['username'] for u in self.client.get('/api/users/liste/').data['results']]
        self.assertIn('nouvel_optic', noms)

        # Boutique visible publiquement
        self.deconnecter()
        boutiques = [b['nom'] for b in self.client.get('/api/boutiques/').data['results']]
        self.assertIn('Optique Nouvelle', boutiques)

        # Et la connexion fonctionne
        connexion = self.client.post('/api/users/login/', {
            'username': 'nouvel_optic', 'password': self.PAYLOAD['password'],
        }, format='json')
        self.assertEqual(connexion.status_code, 200)

    def test_apres_rejet_rien_napparait(self):
        user = self._inscrire()
        self.connecter(self.admin)
        self.client.post(
            f'/api/users/opticiens/{user.pk}/valider/', {'action': 'rejeter'}, format='json')

        self.deconnecter()
        boutiques = [b['nom'] for b in self.client.get('/api/boutiques/').data['results']]
        self.assertNotIn('Optique Nouvelle', boutiques)

        connexion = self.client.post('/api/users/login/', {
            'username': 'nouvel_optic', 'password': self.PAYLOAD['password'],
        }, format='json')
        self.assertEqual(connexion.status_code, 403)
