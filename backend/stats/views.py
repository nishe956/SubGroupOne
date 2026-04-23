from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Sum, Count
from django.db.models.functions import TruncMonth
from django.utils import timezone
from django.contrib.auth import get_user_model
from montures.models import Monture
from commandes.models import Commande
from users.permissions import IsOpticienOuAdmin
import datetime

User = get_user_model()


class DashboardStats(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        today      = timezone.now().date()
        this_month = today.replace(day=1)

        # Filtrer par opticien si l'utilisateur n'est pas admin
        is_opticien = request.user.role == 'opticien'
        montures_qs = Monture.objects.filter(ajoute_par=request.user) if is_opticien else Monture.objects.all()
        commandes_qs = Commande.objects.filter(monture__ajoute_par=request.user) if is_opticien else Commande.objects.all()

        total_clients     = User.objects.filter(role='client').count()
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

        total_opticiens = User.objects.filter(role='opticien').count()
        chiffre_affaires = commandes_qs.filter(statut__in=['livree', 'livrée']).aggregate(t=Sum('prix_total'))['t'] or 0

        from commandes.models import Commande as C
        statuts_qs = C.objects.values('statut').annotate(nb=Count('id'))
        commandes_par_statut = {s['statut']: s['nb'] for s in statuts_qs}

        return Response({
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


class VentesStats(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        periode = request.query_params.get('periode', '6m')
        days = 30 if periode == '1m' else 90 if periode == '3m' else 365 if periode == '1y' else 180

        since = timezone.now().date() - datetime.timedelta(days=days)
        ventes = (
            Commande.objects.filter(date_commande__date__gte=since)
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
        total  = User.objects.filter(role='client').count()
        actifs = User.objects.filter(role='client', is_active=True).count()
        nouveaux_mois = User.objects.filter(
            role='client',
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
        total      = Monture.objects.count()
        disponibles = Monture.objects.filter(disponible=True, stock__gt=0).count()
        epuises    = Monture.objects.filter(stock=0).count()
        stock_bas  = Monture.objects.filter(stock__gt=0, stock__lte=5).count()
        par_forme  = list(Monture.objects.values('forme').annotate(nb=Count('id')))
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
        total  = Commande.objects.filter(statut__in=['livree', 'livrée']).aggregate(t=Sum('prix_total'))['t'] or 0
        mois   = timezone.now().date().replace(day=1)
        ce_mois = Commande.objects.filter(statut__in=['livree', 'livrée'], date_commande__date__gte=mois).aggregate(t=Sum('prix_total'))['t'] or 0
        return Response({
            'total':   float(total),
            'ce_mois': float(ce_mois),
        })
