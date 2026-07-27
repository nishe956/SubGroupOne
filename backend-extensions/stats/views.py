from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions
from django.db.models import Sum, Count, Avg, F
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
        today     = timezone.now().date()
        this_month = today.replace(day=1)

        # Filtrer par opticien si l'utilisateur n'est pas admin
        is_opticien = request.user.role == 'opticien'
        montures_qs = Monture.objects.filter(ajoute_par=request.user) if is_opticien else Monture.objects.all()
        commandes_qs = Commande.objects.filter(monture__ajoute_par=request.user) if is_opticien else Commande.objects.all()

        total_clients   = User.objects.filter(role='client').count()
        total_commandes = commandes_qs.count()
        commandes_mois  = commandes_qs.filter(date_commande__date__gte=this_month).count()
        revenus_total   = commandes_qs.filter(statut='livrée').aggregate(t=Sum('prix_total'))['t'] or 0
        revenus_mois    = commandes_qs.filter(statut='livrée', date_commande__date__gte=this_month).aggregate(t=Sum('prix_total'))['t'] or 0
        total_montures  = montures_qs.count()
        montures_epuisees = montures_qs.filter(stock=0).count()

        # Monthly sales for chart
        six_months_ago = today - datetime.timedelta(days=180)
        ventes_mensuelles = (
            commandes_qs.filter(date_commande__date__gte=six_months_ago, statut='livrée')
            .annotate(mois=TruncMonth('date_commande'))
            .values('mois')
            .annotate(total=Sum('prix_total'), clients=Count('client', distinct=True))
            .order_by('mois')
        )

        return Response({
            'total_clients':     total_clients,
            'total_commandes':   total_commandes,
            'commandes_mois':    commandes_mois,
            'revenus_total':     float(revenus_total),
            'revenus_mois':      float(revenus_mois),
            'total_montures':    total_montures,
            'montures_epuisees': montures_epuisees,
            'ventes_mensuelles': [
                {
                    'mois':   v['mois'].strftime('%b %Y'),
                    'total':  float(v['total'] or 0),
                    'clients': v['clients'],
                }
                for v in ventes_mensuelles
            ],
        })
