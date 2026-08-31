"""Tests de sécurité — authentification et gestion des sessions (V01, V09, V14, V17, V31)."""
from django.conf import settings
from django.contrib.auth import get_user_model

from .base import MDP, BaseSecurite

User = get_user_model()


class TestJetons(BaseSecurite):

    def test_refresh_token_absent_du_corps_de_reponse(self):
        """Le refresh token ne doit jamais être lisible par JavaScript (V09)."""
        reponse = self.client.post(
            '/api/users/login/', {'username': 'client1', 'password': MDP}, format='json')
        self.assertEqual(reponse.status_code, 200)
        self.assertIn('access', reponse.data)
        self.assertNotIn('refresh', reponse.data)
        # Il est en revanche présent dans un cookie httpOnly.
        cookie = reponse.cookies.get(settings.REFRESH_COOKIE_NAME)
        self.assertIsNotNone(cookie, "Le cookie de rafraîchissement doit être posé.")
        self.assertTrue(cookie['httponly'])

    def test_refresh_refuse_le_token_dans_le_corps(self):
        """Seul le cookie fait foi : passer le token en clair ne doit rien donner."""
        connexion = self.client.post(
            '/api/users/login/', {'username': 'client1', 'password': MDP}, format='json')
        token = connexion.cookies[settings.REFRESH_COOKIE_NAME].value
        self.client.cookies.clear()
        reponse = self.client.post(
            '/api/users/token/refresh/', {'refresh': token}, format='json')
        self.assertEqual(reponse.status_code, 401)

    def test_changement_mot_de_passe_revoque_les_jetons_existants(self):
        """Un access token émis avant le changement doit cesser de fonctionner (V17)."""
        self.connecter(self.client_1)
        self.assertEqual(self.client.get('/api/users/profil/').status_code, 200)

        self.client.post('/api/users/change-password/', {
            'ancien_mot_de_passe': MDP,
            'nouveau_mot_de_passe': 'Nouveau-Mot-De-Passe-2026',
        }, format='json')

        # Le jeton d'accès précédent est toujours présenté : il doit être rejeté.
        self.assertEqual(self.client.get('/api/users/profil/').status_code, 401)

    def test_rejet_opticien_revoque_ses_jetons(self):
        """Un opticien rejeté perd l'accès immédiatement, pas à l'expiration (V17)."""
        self.connecter(self.opticien_a)
        jeton_opticien = self.client._credentials['HTTP_AUTHORIZATION']
        self.assertEqual(self.client.get('/api/users/profil/').status_code, 200)

        self.connecter(self.admin)
        reponse = self.client.post(
            f'/api/users/opticiens/{self.opticien_a.pk}/valider/',
            {'action': 'rejeter'}, format='json')
        self.assertEqual(reponse.status_code, 200)

        self.client.credentials(HTTP_AUTHORIZATION=jeton_opticien)
        self.assertEqual(self.client.get('/api/users/profil/').status_code, 401)


class TestEscaladePrivilege(BaseSecurite):

    def test_client_ne_peut_pas_se_promouvoir_admin(self):
        """`role` et `statut_validation` doivent rester en lecture seule (V-mass-assignment)."""
        self.connecter(self.client_1)
        reponse = self.client.patch('/api/users/profil/', {
            'role': 'admin',
            'statut_validation': 'approuve',
            'is_staff': True,
            'is_superuser': True,
        }, format='json')
        self.assertEqual(reponse.status_code, 200)

        self.client_1.refresh_from_db()
        self.assertEqual(self.client_1.role, 'client')
        self.assertFalse(self.client_1.is_staff)
        self.assertFalse(self.client_1.is_superuser)

    def test_inscription_refuse_le_role_admin(self):
        reponse = self.client.post('/api/users/register/', {
            'username': 'pirate', 'email': 'pirate@test.bf',
            'password': MDP, 'role': 'admin',
        }, format='json')
        self.assertEqual(reponse.status_code, 400)
        self.assertFalse(User.objects.filter(username='pirate').exists())

    def test_opticien_ne_peut_pas_lister_les_utilisateurs(self):
        self.connecter(self.opticien_a)
        self.assertEqual(self.client.get('/api/users/liste/').status_code, 403)


class TestEnumerationEtBruteforce(BaseSecurite):

    def test_inscription_ne_revele_pas_les_comptes_existants(self):
        """Le message ne doit pas distinguer « nom déjà pris » d'une autre erreur (V31)."""
        reponse = self.client.post('/api/users/register/', {
            'username': 'client1', 'email': 'autre@test.bf', 'password': MDP,
        }, format='json')
        self.assertEqual(reponse.status_code, 400)
        message = str(reponse.data).lower()
        self.assertNotIn('existe', message)
        self.assertNotIn('déjà', message)

    def test_login_message_identique_compte_existant_ou_non(self):
        connu = self.client.post(
            '/api/users/login/', {'username': 'client1', 'password': 'faux'}, format='json')
        inconnu = self.client.post(
            '/api/users/login/', {'username': 'inexistant', 'password': 'faux'}, format='json')
        self.assertEqual(connu.status_code, inconnu.status_code)
        self.assertEqual(connu.data['detail'], inconnu.data['detail'])

    def test_bruteforce_bloque_apres_cinq_tentatives(self):
        for _ in range(5):
            self.client.post(
                '/api/users/login/', {'username': 'client1', 'password': 'faux'}, format='json')
        reponse = self.client.post(
            '/api/users/login/', {'username': 'client1', 'password': MDP}, format='json')
        self.assertEqual(reponse.status_code, 429)

    def test_mot_de_passe_faible_refuse(self):
        reponse = self.client.post('/api/users/register/', {
            'username': 'nouveau', 'email': 'n@test.bf', 'password': '12345678',
        }, format='json')
        self.assertEqual(reponse.status_code, 400)
        self.assertIn('password', reponse.data)


class TestResetMotDePasse(BaseSecurite):

    def test_reponse_generique_quel_que_soit_lemail(self):
        connu = self.client.post(
            '/api/users/password-reset/', {'email': 'c1@test.bf'}, format='json')
        inconnu = self.client.post(
            '/api/users/password-reset/', {'email': 'personne@test.bf'}, format='json')
        self.assertEqual(connu.status_code, 200)
        self.assertEqual(connu.data['detail'], inconnu.data['detail'])
