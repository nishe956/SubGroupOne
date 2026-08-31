from rest_framework import permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Sum, Count, Avg, Case, When, DecimalField, Value
from utils.throttles import ThrottleIP
from django.db.models.functions import TruncMonth, TruncDate
from django.utils import timezone
from django.contrib.auth import get_user_model
from montures.models import Monture
from commandes.models import Commande
from users.permissions import IsOpticienOuAdmin
from .models import Visite
import datetime

User = get_user_model()

# Statuts considérés comme une vente réalisée (cohérent avec le reste de l'app).
STATUTS_VENDUS = ['livree', 'livrée']


class DashboardStats(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        today      = timezone.now().date()
        this_month = today.replace(day=1)

        # Filtrer par opticien si l'utilisateur n'est pas admin
        is_opticien = request.user.role == 'opticien'
        montures_qs = Monture.objects.filter(ajoute_par=request.user) if is_opticien else Monture.objects.all()
        commandes_qs = Commande.objects.filter(monture__ajoute_par=request.user) if is_opticien else Commande.objects.all()

        # Un opticien ne compte que ses propres clients : le total réseau est
        # une information commerciale qui n'a pas à circuler entre boutiques.
        clients_qs = (
            User.objects.filter(role='client', commandes__monture__ajoute_par=request.user).distinct()
            if is_opticien else User.objects.filter(role='client')
        )
        total_clients     = clients_qs.count()
        total_commandes   = commandes_qs.count()
        commandes_mois    = commandes_qs.filter(date_commande__date__gte=this_month).count()
        revenus_total     = commandes_qs.filter(statut__in=['livree', 'livrée']).aggregate(t=Sum('prix_total'))['t'] or 0
        revenus_mois      = commandes_qs.filter(statut__in=['livree', 'livrée'], date_commande__date__gte=this_month).aggregate(t=Sum('prix_total'))['t'] or 0
        total_montures    = montures_qs.count()
        montures_epuisees = montures_qs.filter(stock=0).count()

        six_months_ago = today - datetime.timedelta(days=180)
        ventes_mensuelles = (
            commandes_qs.filter(date_commande__date__gte=six_months_ago, statut__in=['livree', 'livrée'])
            .annotate(mois=TruncMonth('date_commande'))
            .values('mois')
            .annotate(total=Sum('prix_total'), clients=Count('client', distinct=True))
            .order_by('mois')
        )

        total_opticiens = 0 if is_opticien else User.objects.filter(role='opticien').count()
        chiffre_affaires = commandes_qs.filter(statut__in=['livree', 'livrée']).aggregate(t=Sum('prix_total'))['t'] or 0

        statuts_qs = commandes_qs.values('statut').annotate(nb=Count('id'))
        commandes_par_statut = {s['statut']: s['nb'] for s in statuts_qs}

        # Répartition du chiffre d'affaires par boutique — ADMIN UNIQUEMENT.
        # Un opticien ne doit jamais voir le CA de ses concurrents : c'est
        # exactement le cloisonnement mis en place dans le reste de l'API.
        revenus_par_boutique = [] if is_opticien else self._revenus_par_boutique(this_month)

        return Response({
            'revenus_par_boutique': revenus_par_boutique,
            'total_clients':        total_clients,
            'total_opticiens':      total_opticiens,
            'total_commandes':      total_commandes,
            'commandes_mois':       commandes_mois,
            'chiffre_affaires':     float(chiffre_affaires),
            'revenus_total':        float(revenus_total),
            'revenus_mois':         float(revenus_mois),
            'total_montures':       total_montures,
            'montures_epuisees':    montures_epuisees,
            'commandes_par_statut': commandes_par_statut,
            'ventes_mensuelles': [
                {
                    'mois':    v['mois'].strftime('%b %Y'),
                    'total':   float(v['total'] or 0),
                    'clients': v['clients'],
                }
                for v in ventes_mensuelles
            ],
        })


    @staticmethod
    def _revenus_par_boutique(debut_mois):
        """Chiffre d'affaires réalisé par chaque boutique.

        Le regroupement se fait sur `opticien`, renseigné à la création de la
        commande depuis `monture.ajoute_par` : il survit à la suppression d'une
        monture, contrairement à une jointure passant par le catalogue.
        """
        montant_du_mois = Case(
            When(date_commande__date__gte=debut_mois, then='prix_total'),
            default=Value(0),
            output_field=DecimalField(max_digits=12, decimal_places=2),
        )

        lignes = (
            Commande.objects
            .filter(statut__in=STATUTS_VENDUS)
            .values('opticien', 'opticien__username', 'opticien__boutique__nom')
            .annotate(
                ca_total=Sum('prix_total'),
                ca_mois=Sum(montant_du_mois),
                nb_ventes=Count('id'),
            )
            .order_by('-ca_total')
        )

        return [
            {
                'opticien_id': l['opticien'],
                'boutique': (
                    l['opticien__boutique__nom']
                    or l['opticien__username']
                    or 'Boutique supprimée'
                ),
                'ca_total':  float(l['ca_total'] or 0),
                'ca_mois':   float(l['ca_mois'] or 0),
                'nb_ventes': l['nb_ventes'],
            }
            for l in lignes
        ]

def commandes_visibles(user):
    """Un opticien ne voit que ses propres ventes.

    VentesStats, ClientsStats, MonturesStats et RevenusStats travaillaient sur
    l'ensemble du réseau : chaque opticien connaissait le chiffre d'affaires et
    le volume de ses concurrents.
    """
    if user.role == 'opticien':
        return Commande.objects.filter(monture__ajoute_par=user)
    return Commande.objects.all()


def montures_visibles(user):
    if user.role == 'opticien':
        return Monture.objects.filter(ajoute_par=user)
    return Monture.objects.all()


class VentesStats(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        periode = request.query_params.get('periode', '6m')
        days = 30 if periode == '1m' else 90 if periode == '3m' else 365 if periode == '1y' else 180

        since = timezone.now().date() - datetime.timedelta(days=days)
        ventes = (
            commandes_visibles(request.user).filter(date_commande__date__gte=since)
            .annotate(mois=TruncMonth('date_commande'))
            .values('mois')
            .annotate(total=Sum('prix_total'), nb=Count('id'))
            .order_by('mois')
        )
        return Response([
            {'mois': v['mois'].strftime('%b %Y'), 'total': float(v['total'] or 0), 'nb': v['nb']}
            for v in ventes
        ])


class ClientsStats(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        if request.user.role == 'opticien':
            base = User.objects.filter(
                role='client', commandes__monture__ajoute_par=request.user
            ).distinct()
        else:
            base = User.objects.filter(role='client')
        total  = base.count()
        actifs = base.filter(is_active=True).count()
        nouveaux_mois = base.filter(
            date_joined__date__gte=timezone.now().date().replace(day=1)
        ).count()
        return Response({
            'total':         total,
            'actifs':        actifs,
            'nouveaux_mois': nouveaux_mois,
        })


class MonturesStats(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        qs = montures_visibles(request.user)
        total      = qs.count()
        disponibles = qs.filter(disponible=True, stock__gt=0).count()
        epuises    = qs.filter(stock=0).count()
        stock_bas  = qs.filter(stock__gt=0, stock__lte=5).count()
        par_forme  = list(qs.values('forme').annotate(nb=Count('id')))
        return Response({
            'total':        total,
            'disponibles':  disponibles,
            'epuises':      epuises,
            'stock_bas':    stock_bas,
            'par_forme':    par_forme,
        })


class RevenusStats(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        qs = commandes_visibles(request.user).filter(statut__in=STATUTS_VENDUS)
        total  = qs.aggregate(t=Sum('prix_total'))['t'] or 0
        mois   = timezone.now().date().replace(day=1)
        ce_mois = qs.filter(date_commande__date__gte=mois).aggregate(t=Sum('prix_total'))['t'] or 0
        return Response({
            'total':   float(total),
            'ce_mois': float(ce_mois),
        })


class VisiteThrottle(ThrottleIP):
    """Quota dédié aux pages vues (voir DEFAULT_THROTTLE_RATES['visites']).

    Basé sur ThrottleIP et non sur AnonRateThrottle : cette dernière ne
    s'applique qu'aux requêtes anonymes, si bien qu'un simple compte connecté
    suffisait à écrire sans limite dans la table des visites.
    """
    scope = 'visites'


class EnregistrerVisite(APIView):
    """Enregistre une page vue. Public : les visiteurs non connectés comptent aussi.

    Corps attendu : {"chemin": "/catalogue", "visiteur": "<id anonyme>", "monture": 12}
    """
    permission_classes = [permissions.AllowAny]
    # Remplace les quotas globaux : une navigation normale génère bien plus de
    # requêtes qu'un appel API classique, le quota 'anon' (100/jour) la bloquerait.
    throttle_classes = [VisiteThrottle]

    def post(self, request):
        chemin = str(request.data.get('chemin') or '').strip()[:255]
        if not chemin:
            return Response({'detail': 'chemin requis.'}, status=status.HTTP_400_BAD_REQUEST)

        monture = None
        monture_id = request.data.get('monture')
        if monture_id:
            try:
                monture = Monture.objects.filter(pk=int(monture_id)).first()
            except (TypeError, ValueError):
                monture = None

        Visite.objects.create(
            chemin=chemin,
            monture=monture,
            opticien=monture.ajoute_par if monture else None,
            utilisateur=request.user if request.user.is_authenticated else None,
            visiteur=(request.data.get('visiteur') or '').strip()[:64],
        )
        return Response(status=status.HTTP_204_NO_CONTENT)


class StatistiquesAvancees(APIView):
    """Agrégats de la page Statistiques.

    L'admin voit l'ensemble du réseau ; un opticien ne voit que ses propres
    montures, commandes et visites.
    """
    permission_classes = [IsOpticienOuAdmin]

    PERIODES = {'7j': 7, '30j': 30, '90j': 90, '12m': 365}

    @staticmethod
    def _evolution(actuel, precedent):
        """Variation en % par rapport à la période précédente (None si pas de base)."""
        if not precedent:
            return None
        return round((actuel - precedent) / precedent * 100, 1)

    @staticmethod
    def _buckets(debut, fin, par_mois):
        """Liste ordonnée des intervalles (jours ou mois) couvrant la période."""
        courant, fin = debut.date(), fin.date()
        buckets = []
        if par_mois:
            courant = courant.replace(day=1)
            while courant <= fin:
                buckets.append(courant)
                courant = (courant + datetime.timedelta(days=32)).replace(day=1)
        else:
            while courant <= fin:
                buckets.append(courant)
                courant += datetime.timedelta(days=1)
        return buckets

    @staticmethod
    def _grouper(qs, champ_date, tronquer, agregats):
        """Groupe par jour/mois et renvoie {date: {agrégats}}."""
        lignes = (
            qs.annotate(bucket=tronquer(champ_date))
              .values('bucket')
              .annotate(**agregats)
              .order_by('bucket')
        )
        resultat = {}
        for ligne in lignes:
            bucket = ligne.pop('bucket')
            if bucket is None:
                continue
            # TruncMonth renvoie un datetime, TruncDate une date.
            resultat[bucket.date() if hasattr(bucket, 'date') else bucket] = ligne
        return resultat

    def get(self, request):
        periode = request.query_params.get('periode', '30j')
        jours = self.PERIODES.get(periode, 30)

        maintenant = timezone.now()
        debut = maintenant - datetime.timedelta(days=jours)
        debut_precedent = debut - datetime.timedelta(days=jours)

        est_opticien = request.user.role == 'opticien'
        commandes = (
            Commande.objects.filter(monture__ajoute_par=request.user)
            if est_opticien else Commande.objects.all()
        )
        visites = (
            Visite.objects.filter(opticien=request.user)
            if est_opticien else Visite.objects.all()
        )

        # Au-delà de 6 mois un point par mois reste lisible ; en deçà, un point par jour.
        par_mois = jours > 180
        tronquer = TruncMonth if par_mois else TruncDate
        fmt = '%b %Y' if par_mois else '%d/%m'
        buckets = self._buckets(debut, maintenant, par_mois)

        # ---- Ventes ---------------------------------------------------------
        ventes = commandes.filter(statut__in=STATUTS_VENDUS, date_commande__gte=debut)
        ventes_avant = commandes.filter(
            statut__in=STATUTS_VENDUS,
            date_commande__gte=debut_precedent, date_commande__lt=debut,
        )
        ca = float(ventes.aggregate(t=Sum('prix_total'))['t'] or 0)
        ca_avant = float(ventes_avant.aggregate(t=Sum('prix_total'))['t'] or 0)
        nb_ventes = ventes.count()

        ventes_par_bucket = self._grouper(
            ventes, 'date_commande', tronquer,
            {'ca': Sum('prix_total'), 'nb': Count('id')},
        )

        # ---- Visites --------------------------------------------------------
        visites_periode = visites.filter(date__gte=debut)
        nb_visites = visites_periode.count()
        nb_visites_avant = visites.filter(
            date__gte=debut_precedent, date__lt=debut
        ).count()
        uniques = visites_periode.values('visiteur').distinct().count()

        visites_par_bucket = self._grouper(
            visites_periode, 'date', tronquer,
            {'total': Count('id'), 'uniques': Count('visiteur', distinct=True)},
        )

        # ---- Clients --------------------------------------------------------
        # Pour l'admin : les inscriptions. Pour un opticien : les clients qui ont
        # commandé chez lui (il n'a pas de visibilité sur les inscriptions globales).
        if est_opticien:
            clients_label = 'Clients ayant commandé'
            clients_par_bucket = self._grouper(
                commandes.filter(date_commande__gte=debut), 'date_commande', tronquer,
                {'valeur': Count('client', distinct=True)},
            )
            nouveaux_clients = (
                commandes.filter(date_commande__gte=debut)
                .values('client').distinct().count()
            )
        else:
            clients_label = 'Nouveaux clients'
            nouveaux_qs = User.objects.filter(role='client', date_joined__gte=debut)
            clients_par_bucket = self._grouper(
                nouveaux_qs, 'date_joined', tronquer, {'valeur': Count('id')},
            )
            nouveaux_clients = nouveaux_qs.count()

        # ---- Commandes & conversion -----------------------------------------
        commandes_periode = commandes.filter(date_commande__gte=debut)
        par_statut = {
            l['statut']: l['nb']
            for l in commandes_periode.values('statut').annotate(nb=Count('id'))
        }
        paiements = {
            (l['methode_paiement'] or 'non renseigné'): l['nb']
            for l in commandes_periode.values('methode_paiement').annotate(nb=Count('id'))
        }
        traitees = commandes_periode.exclude(statut='en_attente')
        nb_traitees = traitees.count()
        nb_rejetees = traitees.filter(statut='rejetee').count()
        taux_validation = (
            round((nb_traitees - nb_rejetees) / nb_traitees * 100, 1)
            if nb_traitees else None
        )

        # ---- Montures les plus consultées ------------------------------------
        ventes_par_monture = dict(
            ventes.exclude(monture__isnull=True)
                  .values_list('monture')
                  .annotate(n=Count('id'))
        )
        top_montures = [
            {
                'id':      l['monture'],
                'nom':     l['monture__nom'],
                'marque':  l['monture__marque'],
                'vues':    l['vues'],
                'ventes':  ventes_par_monture.get(l['monture'], 0),
            }
            for l in (
                visites_periode.filter(monture__isnull=False)
                .values('monture', 'monture__nom', 'monture__marque')
                .annotate(vues=Count('id'))
                .order_by('-vues')[:8]
            )
        ]

        pages_populaires = [
            {'chemin': l['chemin'], 'vues': l['vues']}
            for l in (
                visites_periode.values('chemin')
                .annotate(vues=Count('id'))
                .order_by('-vues')[:8]
            )
        ]

        return Response({
            'periode':      periode,
            'granularite':  'mois' if par_mois else 'jour',
            'clients_label': clients_label,
            'resume': {
                'ca':                 ca,
                'ca_evolution':       self._evolution(ca, ca_avant),
                'ventes':             nb_ventes,
                'panier_moyen':       round(ca / nb_ventes) if nb_ventes else 0,
                'visites':            nb_visites,
                'visites_evolution':  self._evolution(nb_visites, nb_visites_avant),
                'visiteurs_uniques':  uniques,
                # Part des visiteurs uniques ayant abouti à une vente.
                'taux_conversion':    round(nb_ventes / uniques * 100, 1) if uniques else None,
                'nouveaux_clients':   nouveaux_clients,
                'taux_validation':    taux_validation,
                'commandes_total':    commandes_periode.count(),
            },
            'series': {
                'ventes': [
                    {
                        'label': b.strftime(fmt),
                        'ca':    float(ventes_par_bucket.get(b, {}).get('ca') or 0),
                        'nb':    ventes_par_bucket.get(b, {}).get('nb', 0),
                    }
                    for b in buckets
                ],
                'visites': [
                    {
                        'label':   b.strftime(fmt),
                        'visites': visites_par_bucket.get(b, {}).get('total', 0),
                        'uniques': visites_par_bucket.get(b, {}).get('uniques', 0),
                    }
                    for b in buckets
                ],
                'clients': [
                    {
                        'label':  b.strftime(fmt),
                        'valeur': clients_par_bucket.get(b, {}).get('valeur', 0),
                    }
                    for b in buckets
                ],
            },
            'commandes_par_statut': par_statut,
            'methodes_paiement':    paiements,
            'top_montures':         top_montures,
            'pages_populaires':     pages_populaires,
        })
