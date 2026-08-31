from django.db.models import Count, F, Sum
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from montures.models import Monture
from users.permissions import IsOpticienOuAdmin
from utils.audit import journaliser


def montures_visibles(user):
    """Un opticien ne voit que son propre stock.

    Toutes les vues de ce module opéraient sur `Monture.objects.all()` : chaque
    opticien connaissait le stock, les ruptures et la valorisation du réseau
    entier — y compris ceux de ses concurrents directs.
    """
    qs = Monture.objects.all()
    if user.role == 'opticien':
        return qs.filter(ajoute_par=user)
    return qs


class StockOverview(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        montures = montures_visibles(request.user)
        return Response({
            'total_montures':   montures.count(),
            'disponibles':      montures.filter(disponible=True, stock__gt=0).count(),
            'epuises':          montures.filter(stock=0).count(),
            'stock_bas':        montures.filter(stock__gt=0, stock__lte=5).count(),
            'valeur_stock_cfa': float(
                montures.aggregate(v=Sum(F('prix') * F('stock')))['v'] or 0
            ),
        })


class AlertesStock(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        from montures.serializers import MontureSerializer

        alertes = montures_visibles(request.user).filter(stock__lte=5).order_by('stock')[:100]
        return Response(MontureSerializer(alertes, many=True).data)


class AjustementStock(APIView):
    permission_classes = [IsOpticienOuAdmin]

    TYPES_VALIDES = ('ajustement', 'entree', 'sortie')

    def post(self, request):
        monture_id = request.data.get('monture_id')
        type_mvt = request.data.get('type', 'ajustement')

        if type_mvt not in self.TYPES_VALIDES:
            return Response(
                {'detail': f'Type de mouvement invalide. Options : {list(self.TYPES_VALIDES)}'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            quantite = int(request.data.get('quantite', 0))
        except (TypeError, ValueError):
            return Response(
                {'detail': 'La quantité doit être un entier.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if quantite < 0:
            return Response(
                {'detail': 'La quantité ne peut pas être négative.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Contrôle de propriété : n'importe quel opticien pouvait auparavant
        # ajuster le stock de n'importe quelle monture, y compris celles des
        # autres boutiques.
        monture = montures_visibles(request.user).filter(pk=monture_id).first()
        if monture is None:
            return Response({'detail': 'Monture introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        ancien_stock = monture.stock
        if type_mvt == 'ajustement':
            monture.stock = quantite
        elif type_mvt == 'entree':
            monture.stock += quantite
        else:  # sortie
            monture.stock = max(0, monture.stock - quantite)

        monture.disponible = monture.stock > 0
        monture.save(update_fields=['stock', 'disponible'])

        journaliser('stock_ajuste', request.user, monture_id=monture.pk,
                    mouvement=type_mvt, ancien=ancien_stock, nouveau=monture.stock)

        return Response({
            'detail':        'Stock mis à jour.',
            'ancien_stock':  ancien_stock,
            'nouveau_stock': monture.stock,
            'monture':       monture.nom,
        })


class RapportStock(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        from montures.serializers import MontureSerializer

        montures = montures_visibles(request.user)
        top_ventes = (
            montures.filter(commande__isnull=False)
            .annotate(nb_commandes=Count('commande'))
            .order_by('-nb_commandes')[:5]
        )

        return Response({
            'epuises':    MontureSerializer(montures.filter(stock=0)[:100], many=True).data,
            'stock_bas':  MontureSerializer(
                montures.filter(stock__gt=0, stock__lte=5)[:100], many=True
            ).data,
            'top_ventes': MontureSerializer(top_ventes, many=True).data,
        })


class MouvementsStock(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        from montures.serializers import MontureSerializer

        montures = montures_visibles(request.user).order_by('stock')[:20]
        return Response(MontureSerializer(montures, many=True).data)
