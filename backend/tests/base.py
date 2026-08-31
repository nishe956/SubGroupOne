"""Socle commun des tests de sécurité."""
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.test import override_settings
from rest_framework.test import APITestCase

from assurance.models import CompagnieAssurance
from commandes.models import Commande
from montures.models import Monture
from ordonnances.models import Ordonnance

User = get_user_model()

MDP = 'Correct-Horse-Battery-2026'


# Hachage rapide pour les tests uniquement. PBKDF2 est volontairement lent (c'est
# sa raison d'être en production) ; avec cinq comptes créés par test, la suite
# passait de quelques secondes à plusieurs minutes. Cette bascule ne concerne que
# l'exécution des tests, jamais le code applicatif.
@override_settings(PASSWORD_HASHERS=['django.contrib.auth.hashers.MD5PasswordHasher'])
class BaseSecurite(APITestCase):
    """Jeu de données minimal : deux opticiens concurrents, deux clients, un admin."""

    def setUp(self):
        # Les compteurs anti-bruteforce vivent dans le cache : sans purge, un test
        # de limitation ferait échouer les suivants.
        cache.clear()

        self.admin = User.objects.create_user(
            username='admin', email='admin@test.bf', password=MDP, role='admin')
        self.opticien_a = User.objects.create_user(
            username='optic_a', email='a@test.bf', password=MDP, role='opticien')
        self.opticien_b = User.objects.create_user(
            username='optic_b', email='b@test.bf', password=MDP, role='opticien')
        self.client_1 = User.objects.create_user(
            username='client1', email='c1@test.bf', password=MDP, role='client')
        self.client_2 = User.objects.create_user(
            username='client2', email='c2@test.bf', password=MDP, role='client')

        self.monture_a = Monture.objects.create(
            nom='Modele A', marque='MarqueA', prix=Decimal('50000'), forme='ronde',
            couleur='noir', stock=5, ajoute_par=self.opticien_a)
        self.monture_b = Monture.objects.create(
            nom='Modele B', marque='MarqueB', prix=Decimal('30000'), forme='carree',
            couleur='bleu', stock=3, ajoute_par=self.opticien_b)

        self.ordonnance_1 = Ordonnance.objects.create(client=self.client_1)
        self.ordonnance_2 = Ordonnance.objects.create(client=self.client_2)

        self.compagnie = CompagnieAssurance.objects.create(
            nom='Assur Test', code='AT', taux_prise_charge=Decimal('80.00'))

        self.commande_1 = Commande.objects.create(
            client=self.client_1, monture=self.monture_a, opticien=self.opticien_a,
            prix_total=Decimal('50000'), statut='validee')

    def connecter(self, user):
        """Authentifie le client de test via l'API réelle (pas force_authenticate) :
        on veut aussi valider le chemin d'émission des jetons."""
        reponse = self.client.post(
            '/api/users/login/', {'username': user.username, 'password': MDP}, format='json')
        assert reponse.status_code == 200, reponse.data
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {reponse.data['access']}")
        return reponse

    def deconnecter(self):
        self.client.credentials()
