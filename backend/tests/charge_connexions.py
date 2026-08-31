"""Simulation de charge : 300 connexions successives.

Lancement explicite (le fichier n'est pas découvert par la suite de tests) :
    python manage.py test tests.charge_connexions -v 2

Deux scénarios :
  1. 300 utilisateurs distincts, chacun depuis sa propre adresse IP — le cas
     réaliste d'un pic de fréquentation.
  2. 300 connexions depuis une seule IP — vérifie que la limitation de débit
     posée pendant l'audit fait bien barrage.

La base utilisée est la base de TEST, créée puis détruite automatiquement :
les données réelles ne sont pas touchées.
"""
import statistics
import time

from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.test import TestCase

User = get_user_model()

NB_UTILISATEURS = 300
MDP = 'Correct-Horse-Battery-2026'


def _percentile(valeurs, p):
    ordonnees = sorted(valeurs)
    k = max(0, min(len(ordonnees) - 1, int(round((p / 100) * len(ordonnees) + 0.5)) - 1))
    return ordonnees[k]


def _rapport(titre, durees, echecs, duree_totale, codes):
    print(f"\n{'═' * 66}")
    print(f"  {titre}")
    print('═' * 66)
    print(f"  Connexions tentées   : {len(durees) + echecs}")
    print(f"  Réussies             : {len(durees)}")
    print(f"  Refusées             : {echecs}")
    print(f"  Durée totale         : {duree_totale:.2f} s")
    if duree_totale > 0:
        print(f"  Débit                : {(len(durees) + echecs) / duree_totale:.1f} req/s")
    if durees:
        print(f"\n  Latence (ms) — connexions réussies")
        print(f"    min    : {min(durees) * 1000:7.1f}")
        print(f"    médiane: {statistics.median(durees) * 1000:7.1f}")
        print(f"    p90    : {_percentile(durees, 90) * 1000:7.1f}")
        print(f"    p99    : {_percentile(durees, 99) * 1000:7.1f}")
        print(f"    max    : {max(durees) * 1000:7.1f}")
        print(f"    moyenne: {statistics.mean(durees) * 1000:7.1f}")
    if codes:
        print(f"\n  Répartition des codes HTTP : "
              + ', '.join(f'{c}×{n}' for c, n in sorted(codes.items())))


class SimulationConnexions(TestCase):

    @classmethod
    def setUpTestData(cls):
        # `bulk_create` ne hache pas les mots de passe : on passe par
        # `set_password` une seule fois, puis on réutilise l'empreinte. Cela
        # accélère la préparation sans fausser la mesure, qui porte sur la
        # VÉRIFICATION du mot de passe, pas sur sa création.
        gabarit = User(username='_gabarit')
        gabarit.set_password(MDP)
        empreinte = gabarit.password

        User.objects.bulk_create([
            User(
                username=f'charge_{i:03d}',
                email=f'charge{i:03d}@test.bf',
                password=empreinte,
                role='client',
                is_active=True,
            )
            for i in range(NB_UTILISATEURS)
        ])
        print(f"\n  {NB_UTILISATEURS} comptes créés pour la simulation.")

    def setUp(self):
        cache.clear()

    def _connecter(self, index, ip):
        depart = time.perf_counter()
        reponse = self.client.post(
            '/api/users/login/',
            {'username': f'charge_{index:03d}', 'password': MDP},
            content_type='application/json',
            REMOTE_ADDR=ip,
        )
        return time.perf_counter() - depart, reponse.status_code

    def test_1_utilisateurs_distincts_ips_distinctes(self):
        """Cas réaliste : 300 personnes différentes, depuis 300 connexions."""
        durees, echecs, codes = [], 0, {}
        debut = time.perf_counter()

        for i in range(NB_UTILISATEURS):
            # IP unique par utilisateur, comme en conditions réelles.
            ip = f'10.{i // 256}.{i % 256}.1'
            duree, code = self._connecter(i, ip)
            codes[code] = codes.get(code, 0) + 1
            if code == 200:
                durees.append(duree)
            else:
                echecs += 1

        total = time.perf_counter() - debut
        _rapport('SCÉNARIO 1 — 300 utilisateurs, IP distinctes',
                 durees, echecs, total, codes)

        self.assertEqual(echecs, 0, "Aucune connexion légitime ne doit être refusée.")

    def test_2_meme_ip_la_limitation_protege(self):
        """Cas d'attaque : 300 tentatives depuis une seule adresse."""
        durees, echecs, codes = [], 0, {}
        debut = time.perf_counter()

        for i in range(NB_UTILISATEURS):
            duree, code = self._connecter(i, '203.0.113.99')
            codes[code] = codes.get(code, 0) + 1
            if code == 200:
                durees.append(duree)
            else:
                echecs += 1

        total = time.perf_counter() - debut
        _rapport('SCÉNARIO 2 — 300 connexions depuis UNE SEULE IP',
                 durees, echecs, total, codes)

        self.assertEqual(
            codes.get(429, 0), NB_UTILISATEURS - 10,
            "Au-delà du quota horaire, tout doit être refusé en 429.",
        )
        print("\n  → La limitation de débit a bloqué "
              f"{codes.get(429, 0)} tentatives sur {NB_UTILISATEURS}.")
