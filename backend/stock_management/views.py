from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions
from django.db.models import Sum, Count, F
from montures.models import Monture
from users.permissions import IsOpticienOuAdmin


class StockOverview(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        montures  = Monture.objects.all()
        total     = montures.count()
        disponibles = montures.filter(disponible=True, stock__gt=0).count()
        epuises   = montures.filter(stock=0).count()
        stock_bas = montures.filter(stock__gt=0, stock__lte=5).count()
        valeur    = montures.aggregate(v=Sum(F('prix') * F('stock')))['v'] or 0

        return Response({
            'total_montures':   total,
            'disponibles':      disponibles,
            'epuises':          epuises,
            'stock_bas':        stock_bas,
            'valeur_stock_cfa': float(valeur),
        })


class AlertesStock(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        from montures.serializers import MontureSerializer
        alertes = Monture.objects.filter(stock__lte=5).order_by('stock')
        from montures.serializers import MontureSerializer
        return Response(MontureSerializer(alertes, many=True).data)


class AjustementStock(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def post(self, request):
        monture_id = request.data.get('monture_id')
        quantite   = int(request.data.get('quantite', 0))
        type_mvt   = request.data.get('type', 'ajustement')  # ajustement | entree | sortie

        try:
            monture = Monture.objects.get(pk=monture_id)
        except Monture.DoesNotExist:
            return Response({'detail': 'Monture introuvable.'}, status=404)

        ancien_stock = monture.stock
        if type_mvt == 'ajustement':
            monture.stock = quantite
        elif type_mvt == 'entree':
            monture.stock += quantite
        elif type_mvt == 'sortie':
            monture.stock = max(0, monture.stock - quantite)

        monture.disponible = monture.stock > 0
        monture.save(update_fields=['stock', 'disponible'])

        return Response({
            'detail':       'Stock mis à jour.',
            'ancien_stock': ancien_stock,
            'nouveau_stock': monture.stock,
            'monture':      monture.nom,
        })


class RapportStock(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        from montures.serializers import MontureSerializer
        epuises    = Monture.objects.filter(stock=0)
        bas        = Monture.objects.filter(stock__gt=0, stock__lte=5)
        top_ventes = Monture.objects.filter(commandes__isnull=False).annotate(nb_commandes=Count('commandes')).order_by('-nb_commandes')[:5]

        return Response({
            'epuises':    MontureSerializer(epuises, many=True).data,
            'stock_bas':  MontureSerializer(bas, many=True).data,
            'top_ventes': MontureSerializer(top_ventes, many=True).data,
        })


class MouvementsStock(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        from montures.serializers import MontureSerializer
        # Retourne les montures avec stock faible comme "alertes de mouvement"
        montures = Monture.objects.order_by('stock')[:20]
        return Response(MontureSerializer(montures, many=True).data)
