"""Tests de sécurité — validation des entrées, OTP, en-têtes, configuration."""
from django.conf import settings
from django.core.exceptions import ImproperlyConfigured
from django.test import SimpleTestCase, override_settings

from .base import BaseSecurite


class TestOTP(BaseSecurite):
    """V15/V16 : SMS bombing, toll fraud, code prévisible."""

    def test_numero_invalide_refuse(self):
        for numero in ['', 'abc', '12345', '0022670000000000000000', '<script>']:
            with self.subTest(numero=numero):
                reponse = self.client.post(
                    '/api/sms/envoyer/', {'telephone': numero}, format='json')
                self.assertEqual(reponse.status_code, 400)

    def test_prefixe_non_desservi_refuse(self):
        """Empêche l'envoi vers des préfixes internationaux surtaxés."""
        reponse = self.client.post(
            '/api/sms/envoyer/', {'telephone': '+18005550100'}, format='json')
        self.assertEqual(reponse.status_code, 400)

    def test_code_jamais_renvoye_dans_la_reponse(self):
        reponse = self.client.post(
            '/api/sms/envoyer/', {'telephone': '+22670000001'}, format='json')
        self.assertEqual(reponse.status_code, 200)
        self.assertNotIn('code_dev', reponse.data)
        self.assertNotIn('code', reponse.data)

    def test_code_stocke_hache(self):
        from sms_otp.models import OTPCode

        self.client.post('/api/sms/envoyer/', {'telephone': '+22670000002'}, format='json')
        otp = OTPCode.objects.filter(telephone='+22670000002').first()
        self.assertIsNotNone(otp)
        self.assertEqual(len(otp.code_hash), 64)
        self.assertFalse(otp.code_hash.isdigit())

    def test_quota_par_numero(self):
        for _ in range(3):
            self.client.post('/api/sms/envoyer/', {'telephone': '+22670000003'}, format='json')
        reponse = self.client.post(
            '/api/sms/envoyer/', {'telephone': '+22670000003'}, format='json')
        self.assertEqual(reponse.status_code, 429)

    def test_code_genere_cryptographiquement(self):
        """Le générateur ne doit pas être le Mersenne Twister de `random`.

        Test comportemental plutôt que textuel : on réamorce `random` avec une
        graine fixe et on vérifie que la suite produite n'est PAS reproductible.
        Un générateur seedable rendrait les codes suivants prédictibles à partir
        d'observations suffisantes.
        """
        import random

        from sms_otp.models import generer_code

        random.seed(1234)
        premiere = [generer_code() for _ in range(5)]
        random.seed(1234)
        seconde = [generer_code() for _ in range(5)]
        self.assertNotEqual(
            premiere, seconde,
            "Les codes sont reproductibles à partir d'une graine : générateur non cryptographique.",
        )

    def test_code_au_bon_format(self):
        from sms_otp.models import generer_code

        for _ in range(50):
            code = generer_code()
            self.assertEqual(len(code), 6)
            self.assertTrue(code.isdigit())


class TestGabaritsMessages(SimpleTestCase):
    """V25 : format-string injection dans les gabarits marketing."""

    def test_jeton_inconnu_refuse(self):
        from marketing.tasks import rendre_message

        with self.assertRaises(ValueError):
            rendre_message('Bonjour {inconnu}', prenom='Ali')

    def test_traversee_dattributs_refusee(self):
        from marketing.tasks import rendre_message

        for charge in [
            '{prenom.__class__}',
            '{prenom.__class__.__base__}',
            '{0.__class__}',
            '{prenom!r:>1000000}',
        ]:
            with self.subTest(charge=charge):
                with self.assertRaises(ValueError):
                    rendre_message(charge, prenom='Ali')

    def test_substitution_normale_fonctionne(self):
        from marketing.tasks import rendre_message

        self.assertEqual(
            rendre_message('Bonjour {prenom} !', prenom='Ali'), 'Bonjour Ali !')


class TestValidationFichiers(SimpleTestCase):

    def _fichier(self, contenu, nom='test.jpg'):
        from django.core.files.uploadedfile import SimpleUploadedFile
        return SimpleUploadedFile(nom, contenu)

    def test_extension_trompeuse_refusee(self):
        """Le contenu réel prime sur l'extension."""
        from rest_framework.exceptions import ValidationError

        from utils.validators import valider_image_seulement

        with self.assertRaises(ValidationError):
            valider_image_seulement(self._fichier(b'<?php system($_GET[0]); ?>', 'shell.jpg'))

    def test_svg_refuse(self):
        from rest_framework.exceptions import ValidationError

        from utils.validators import valider_image_seulement

        svg = b'<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>'
        with self.assertRaises(ValidationError):
            valider_image_seulement(self._fichier(svg, 'image.svg'))

    def test_html_refuse(self):
        from rest_framework.exceptions import ValidationError

        from utils.validators import valider_image_seulement

        with self.assertRaises(ValidationError):
            valider_image_seulement(self._fichier(b'<html><body>x</body></html>', 'p.png'))

    def test_nom_de_fichier_randomise(self):
        """Le nom fourni par le client ne doit jamais être réutilisé."""
        from utils.validators import nom_fichier_sur

        nom = nom_fichier_sur('image/jpeg')
        self.assertTrue(nom.endswith('.jpg'))
        self.assertEqual(len(nom), 32 + 4)
        self.assertNotEqual(nom, nom_fichier_sur('image/jpeg'))

    def test_extension_sure_rejette_la_traversee(self):
        from utils.validators import extension_sure

        self.assertIsNone(extension_sure('../../etc/passwd', ('.jpg',)))
        self.assertIsNone(extension_sure('x.php', ('.jpg', '.png')))
        self.assertEqual(extension_sure('photo.JPG', ('.jpg',)), '.jpg')


class TestFacturePDF(BaseSecurite):
    """V32 : injection de balises dans le mini-markup ReportLab."""

    def test_donnees_utilisateur_echappees(self):
        from boutique.models import BoutiqueOpticien
        from commandes.facture import generer_facture_pdf

        BoutiqueOpticien.objects.create(
            opticien=self.opticien_a,
            nom='<font color="red">Boutique</font> & Cie',
            adresse='<b>Rue 1</b>')
        self.client_1.first_name = 'Ali <script>'
        self.client_1.last_name = '& Co'
        self.client_1.save()

        # Sans échappement, ReportLab lèverait une exception de parsing.
        pdf = generer_facture_pdf(self.commande_1)
        self.assertTrue(pdf.startswith(b'%PDF'))


class TestEnTetes(BaseSecurite):

    def test_en_tetes_de_securite_presents(self):
        reponse = self.client.get('/api/montures/')
        self.assertEqual(reponse['X-Frame-Options'], 'DENY')
        self.assertEqual(reponse['X-Content-Type-Options'], 'nosniff')
        self.assertIn('Content-Security-Policy', reponse)
        self.assertIn('Referrer-Policy', reponse)

    def test_xss_protection_obsolete_absent(self):
        """L'en-tête est déconseillé et a introduit ses propres failles."""
        reponse = self.client.get('/api/montures/')
        self.assertNotIn('X-XSS-Protection', reponse)

    def test_pagination_active_et_plafonnee(self):
        """V23 : sans pagination, chaque liste renvoyait toute la table."""
        reponse = self.client.get('/api/montures/?page_size=100000')
        self.assertIn('count', reponse.data)
        self.assertIn('results', reponse.data)
        self.assertLessEqual(len(reponse.data['results']), 100)


class TestConfiguration(SimpleTestCase):

    def test_rotation_et_blacklist_des_refresh_tokens(self):
        self.assertTrue(settings.SIMPLE_JWT['ROTATE_REFRESH_TOKENS'])
        self.assertTrue(settings.SIMPLE_JWT['BLACKLIST_AFTER_ROTATION'])

    def test_cors_jamais_ouvert_a_tous(self):
        self.assertFalse(settings.CORS_ALLOW_ALL_ORIGINS)

    def test_media_root_toujours_defini(self):
        """V03 : indéfini, il retombait sur '' et servait le répertoire de travail."""
        self.assertTrue(str(settings.MEDIA_ROOT))
        self.assertNotEqual(str(settings.MEDIA_ROOT), '')

    def test_proxys_de_confiance_non_implicites(self):
        """V13 : DRF fait confiance à X-Forwarded-For si NUM_PROXIES n'est pas fixé."""
        from rest_framework.settings import api_settings

        self.assertIsNotNone(api_settings.NUM_PROXIES)

    def test_secret_key_faible_refusee_en_production(self):
        """V01 : le garde-fou vivait dans un module jamais chargé."""
        import importlib
        import os
        from unittest import mock

        env = {
            'DEBUG': 'False',
            'SECRET_KEY': 'django-insecure-remplace-cette-cle-par-quelque-chose-de-long',
            'ALLOWED_HOSTS': 'exemple.bf',
            'CORS_ALLOWED_ORIGINS': 'https://exemple.bf',
            'REDIS_URL': 'redis://localhost:6379/0',
        }
        with mock.patch.dict(os.environ, env, clear=False):
            with self.assertRaises(ImproperlyConfigured):
                importlib.reload(importlib.import_module('config.settings'))
        # Restaure la configuration réelle pour les tests suivants.
        importlib.reload(importlib.import_module('config.settings'))


# Les pages de l'admin référencent des fichiers statiques. En production,
# `collectstatic` est exécuté au démarrage (entrypoint.sh) et le stockage
# « manifest » de WhiteNoise résout ces références ; en test, il lèverait une
# erreur faute de manifeste. On repasse donc sur le stockage simple.
@override_settings(STORAGES={
    'default': {'BACKEND': 'django.core.files.storage.FileSystemStorage'},
    'staticfiles': {'BACKEND': 'django.contrib.staticfiles.storage.StaticFilesStorage'},
})
class TestProtectionAdmin(BaseSecurite):
    """V39 : l'admin est la cible de plus forte valeur et la moins protégée.

    Son formulaire de connexion est une vue Django classique : les limites de
    débit DRF posées sur /api/users/login/ ne s'y appliquent pas, ce qui offrait
    une seconde porte non comptée vers les mêmes comptes.
    """

    def setUp(self):
        super().setUp()
        self.admin.is_staff = True
        self.admin.is_superuser = True
        self.admin.save(update_fields=['is_staff', 'is_superuser'])
        self.url_admin = '/' + settings.ADMIN_URL

    def test_prefixe_admin_configurable(self):
        self.assertTrue(settings.ADMIN_URL.endswith('/'))
        from django.urls import get_resolver
        motifs = [str(p.pattern) for p in get_resolver().url_patterns]
        self.assertIn(settings.ADMIN_URL, motifs)

    def test_connexion_admin_limitee_en_debit(self):
        url = self.url_admin + 'login/'
        for _ in range(5):
            self.client.post(url, {'username': 'admin', 'password': 'faux'})
        reponse = self.client.post(url, {'username': 'admin', 'password': 'faux'})
        self.assertEqual(reponse.status_code, 429)

    def test_liste_blanche_ip_renvoie_404(self):
        """404 et non 403 : l'admin doit être indiscernable d'une URL inexistante."""
        with self.settings(ADMIN_IPS=['203.0.113.1']):
            # Le middleware lit ADMIN_IPS à l'instanciation : on le reconstruit.
            from config.admin_security import ProtectionAdminMiddleware
            mw = ProtectionAdminMiddleware(lambda r: None)
            from django.http import Http404
            from django.test import RequestFactory
            requete = RequestFactory().get(self.url_admin)
            requete.META['REMOTE_ADDR'] = '198.51.100.7'
            with self.assertRaises(Http404):
                mw(requete)

    def test_liste_blanche_vide_nempeche_rien(self):
        """En développement, ADMIN_IPS vide ne doit bloquer personne."""
        self.assertEqual(settings.ADMIN_IPS, [])
        reponse = self.client.get(self.url_admin + 'login/')
        self.assertEqual(reponse.status_code, 200)

    def test_role_non_modifiable_depuis_la_liste(self):
        """`list_editable = ['role']` transformait un compte staff compromis en
        administrateur en un clic."""
        from django.contrib import admin as dj_admin

        from users.models import User as UserModel

        options = dj_admin.site._registry[UserModel]
        self.assertNotIn('role', getattr(options, 'list_editable', ()))

    def test_echec_de_connexion_journalise(self):
        with self.assertLogs('audit', level='INFO') as journal:
            self.client.post(self.url_admin + 'login/',
                             {'username': 'admin', 'password': 'faux'})
        self.assertTrue(any('connexion_echouee' in l for l in journal.output))

    def test_mot_de_passe_jamais_journalise(self):
        with self.assertLogs('audit', level='INFO') as journal:
            self.client.post(self.url_admin + 'login/',
                             {'username': 'admin', 'password': 'SuperSecret123'})
        self.assertFalse(any('SuperSecret123' in l for l in journal.output))


class TestUploadOrdonnance(BaseSecurite):
    """Parcours d'upload complet : ce que le client envoie doit être accepté,
    stocké, et re-servi uniquement par l'endpoint authentifié."""

    def _image(self, taille=(600, 400), fmt='JPEG'):
        import io

        from django.core.files.uploadedfile import SimpleUploadedFile
        from PIL import Image

        buf = io.BytesIO()
        Image.new('RGB', taille, 'white').save(buf, format=fmt)
        return SimpleUploadedFile('ordo.jpg', buf.getvalue(), content_type='image/jpeg')

    def test_upload_accepte(self):
        self.connecter(self.client_1)
        reponse = self.client.post(
            '/api/ordonnances/ajouter/', {'image': self._image()}, format='multipart')
        self.assertEqual(reponse.status_code, 201, reponse.data)

    def test_reponse_expose_lendpoint_authentifie_pas_le_stockage(self):
        self.connecter(self.client_1)
        reponse = self.client.post(
            '/api/ordonnances/ajouter/', {'image': self._image()}, format='multipart')
        self.assertIn('image_url', reponse.data)
        self.assertIn('/image/', reponse.data['image_url'])
        # L'URL de stockage ne doit jamais sortir.
        self.assertNotIn('/media/ordonnances/', str(reponse.data))

    def test_image_recuperable_par_le_proprietaire(self):
        self.connecter(self.client_1)
        creation = self.client.post(
            '/api/ordonnances/ajouter/', {'image': self._image()}, format='multipart')
        reponse = self.client.get(f"/api/ordonnances/{creation.data['id']}/image/")
        self.assertEqual(reponse.status_code, 200)
        self.assertEqual(reponse['Cache-Control'], 'private, no-store, max-age=0')

    def test_photo_de_telephone_acceptee(self):
        """Une limite de taille trop basse rejetait des fichiers légitimes."""
        from utils.validators import _TAILLE_MAX_IMAGE

        self.assertGreaterEqual(
            _TAILLE_MAX_IMAGE, 10 * 1024 * 1024,
            "Une ordonnance photographiée pèse couramment 4 à 8 Mo.",
        )

    def test_plafond_du_corps_de_requete_coherent(self):
        """Django rejetterait l'upload avant validation si le plafond global
        était inférieur à la taille de fichier acceptée."""
        from django.conf import settings

        from utils.validators import _TAILLE_MAX_PDF

        self.assertGreater(settings.DATA_UPLOAD_MAX_MEMORY_SIZE, _TAILLE_MAX_PDF)

    def test_bombe_de_decompression_refusee(self):
        self.connecter(self.client_1)
        reponse = self.client.post(
            '/api/ordonnances/ajouter/',
            {'image': self._image(taille=(12000, 12000))}, format='multipart')
        self.assertEqual(reponse.status_code, 400)
