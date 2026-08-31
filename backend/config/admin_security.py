"""Protection de l'interface d'administration Django.

L'admin est la cible de plus forte valeur de l'application : il donne accès en
lecture et en écriture à l'intégralité des données, ordonnances (données de
santé) comprises. C'était pourtant la surface la moins protégée :

- son formulaire de connexion est une vue Django classique, donc **hors de
  portée des limites de débit DRF** posées sur `/api/users/login/` — un
  attaquant disposait de deux portes vers le même compte, dont une non comptée ;
- il répond sur `/admin/`, chemin par défaut testé en permanence par les
  scanners automatisés ;
- il est joignable depuis Internet entier alors que deux ou trois personnes en
  ont l'usage.

Ce module ajoute : limitation du débit sur la connexion, liste blanche d'IP
optionnelle, et journalisation d'audit des connexions réussies comme échouées.
Le préfixe d'URL, lui, est configurable via `ADMIN_URL` (voir config/urls.py).
"""
import logging

from django.conf import settings
from django.contrib.auth.signals import user_logged_in, user_login_failed
from django.core.cache import cache
from django.dispatch import receiver
from django.http import Http404, HttpResponse

from utils.audit import journaliser
from utils.reseau import adresse_client

logger = logging.getLogger(__name__)

TENTATIVES_MAX = 5
FENETRE = 900  # 15 minutes


def _cle_compteur(ip):
    return f'admin_login_attempts_{ip}'


class ProtectionAdminMiddleware:
    """Restreint l'accès à l'admin et limite les tentatives de connexion."""

    def __init__(self, get_response):
        self.get_response = get_response
        self.prefixe = '/' + settings.ADMIN_URL.strip('/') + '/'
        self.ips_autorisees = set(settings.ADMIN_IPS)

    def __call__(self, request):
        if not request.path.startswith(self.prefixe):
            return self.get_response(request)

        ip = adresse_client(request)

        # 1. Liste blanche réseau (inactive si ADMIN_IPS est vide).
        #    On renvoie 404 et non 403 : depuis l'extérieur, l'admin doit être
        #    indiscernable d'une URL qui n'existe pas.
        if self.ips_autorisees and ip not in self.ips_autorisees:
            journaliser('admin_acces_hors_liste_blanche', None, ip=ip, chemin=request.path)
            raise Http404

        # 2. Limitation du débit sur le formulaire de connexion.
        est_connexion = request.method == 'POST' and request.path.rstrip('/').endswith('/login')
        if est_connexion and cache.get(_cle_compteur(ip), 0) >= TENTATIVES_MAX:
            journaliser('admin_connexion_bloquee', None, ip=ip)
            return HttpResponse(
                'Trop de tentatives de connexion. Réessayez dans 15 minutes.',
                status=429, content_type='text/plain; charset=utf-8',
            )

        reponse = self.get_response(request)

        # 3. Comptage. L'admin Django répond 302 en cas de succès et réaffiche le
        #    formulaire (200) en cas d'échec : c'est le signal le plus fiable, la
        #    vue ne levant pas d'exception distincte.
        if est_connexion:
            if reponse.status_code == 200:
                try:
                    cache.incr(_cle_compteur(ip))
                except ValueError:
                    cache.set(_cle_compteur(ip), 1, timeout=FENETRE)
            elif reponse.status_code in (301, 302):
                cache.delete(_cle_compteur(ip))

        return reponse


@receiver(user_logged_in)
def _journaliser_connexion(sender, request, user, **kwargs):
    journaliser(
        'connexion_reussie', user,
        ip=adresse_client(request) if request else 'inconnue',
        admin=bool(request and request.path.startswith('/' + settings.ADMIN_URL.strip('/'))),
    )


@receiver(user_login_failed)
def _journaliser_echec(sender, credentials, request=None, **kwargs):
    # `credentials` est déjà expurgé du mot de passe par Django ; on ne
    # journalise que l'identifiant tenté, jamais le secret présenté.
    journaliser(
        'connexion_echouee', None,
        identifiant=str(credentials.get('username', ''))[:150],
        ip=adresse_client(request) if request else 'inconnue',
    )
