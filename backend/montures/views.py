from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Monture, MontureImage
from .serializers import MontureSerializer, MontureImageSerializer
from users.permissions import IsOpticienOuAdmin
from utils.validators import valider_image_seulement


class ListeMontures(generics.ListCreateAPIView):
    serializer_class = MontureSerializer

    def get_permissions(self):
        if self.request.method == 'GET':
            return [permissions.AllowAny()]
        return [IsOpticienOuAdmin()]

    def get_queryset(self):
        params = self.request.query_params
        qs = Monture.objects.all()

        if params.get('disponible') == 'true':
            qs = qs.filter(disponible=True)

        # Filtre "mes montures" pour un opticien
        if params.get('mes_montures') == 'true' and self.request.user.is_authenticated:
            qs = qs.filter(ajoute_par=self.request.user)

        forme     = params.get('forme')
        couleur   = params.get('couleur')
        marque    = params.get('marque')
        search    = params.get('search')
        categorie = params.get('categorie')
        prix_min  = params.get('prix_min') or params.get('minPrix')
        prix_max  = params.get('prix_max') or params.get('maxPrix')
        sort      = params.get('sort', '-date_ajout')

        if forme:     qs = qs.filter(forme=forme)
        if couleur:   qs = qs.filter(couleur__icontains=couleur)
        if marque:    qs = qs.filter(marque__icontains=marque)
        if categorie: qs = qs.filter(categorie=categorie)
        if search:    qs = qs.filter(nom__icontains=search) | qs.filter(marque__icontains=search)
        if prix_min:  qs = qs.filter(prix__gte=prix_min)
        if prix_max:  qs = qs.filter(prix__lte=prix_max)

        valid_sorts = ['prix', '-prix', 'date_ajout', '-date_ajout', 'nom', '-nom']
        if sort in valid_sorts:
            qs = qs.order_by(sort)

        return qs

    def perform_create(self, serializer):
        """Enregistre automatiquement l'opticien qui ajoute la monture."""
        stock = serializer.validated_data.get('stock', 0)
        serializer.save(ajoute_par=self.request.user, disponible=stock > 0)


class DetailMonture(generics.RetrieveUpdateDestroyAPIView):
    queryset = Monture.objects.all()
    serializer_class = MontureSerializer

    def get_permissions(self):
        if self.request.method == 'GET':
            return [permissions.AllowAny()]
        return [IsOpticienOuAdmin()]

    def check_object_permissions(self, request, obj):
        super().check_object_permissions(request, obj)
        # Un opticien ne peut modifier/supprimer QUE ses propres montures
        # Sauf l'admin qui peut tout faire
        if request.method not in ('GET', 'HEAD', 'OPTIONS'):
            if request.user.role == 'opticien' and obj.ajoute_par != request.user:
                from rest_framework.exceptions import PermissionDenied
                raise PermissionDenied("Vous ne pouvez modifier que vos propres montures.")


class UpdateStockMonture(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def patch(self, request, pk):
        try:
            monture = Monture.objects.get(pk=pk)
        except Monture.DoesNotExist:
            return Response({'detail': 'Monture introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        stock = request.data.get('stock')
        if stock is None:
            return Response({'detail': 'Champ stock requis.'}, status=status.HTTP_400_BAD_REQUEST)

        monture.stock = int(stock)
        monture.disponible = monture.stock > 0
        monture.save(update_fields=['stock', 'disponible'])
        return Response(MontureSerializer(monture).data)


class RecommenderMontures(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        # Recommandations basées sur l'ordonnance ou les préférences
        forme_visage = request.data.get('forme_visage')
        usage        = request.data.get('usage', 'vue')  # vue | solaire | enfant

        qs = Monture.objects.filter(disponible=True, stock__gt=0)

        # Règles de recommandation selon forme du visage
        if forme_visage == 'ovale':
            qs = qs.filter(forme__in=['ronde', 'carree', 'rectangulaire'])
        elif forme_visage == 'rond':
            qs = qs.filter(forme__in=['rectangulaire', 'carree'])
        elif forme_visage == 'carre':
            qs = qs.filter(forme__in=['ronde', 'ovale'])
        elif forme_visage == 'coeur':
            qs = qs.filter(forme__in=['ronde', 'ovale'])

        return Response(MontureSerializer(qs[:8], many=True).data)


class AjouterImage(APIView):
    """Ajouter une image à la galerie d'une monture."""
    permission_classes = [IsOpticienOuAdmin]

    def post(self, request, pk):
        try:
            monture = Monture.objects.get(pk=pk)
        except Monture.DoesNotExist:
            return Response({'detail': 'Monture introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        image = request.FILES.get('image')
        if not image:
            return Response({'detail': 'Image requise.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            valider_image_seulement(image)
        except Exception as e:
            return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)

        ordre = MontureImage.objects.filter(monture=monture).count()
        img   = MontureImage.objects.create(monture=monture, image=image, ordre=ordre)

        # Si c'est la première image galerie, mettre aussi comme image principale
        if not monture.image:
            monture.image = img.image
            monture.save(update_fields=['image'])

        return Response(MontureImageSerializer(img).data, status=status.HTTP_201_CREATED)


class SupprimerImage(APIView):
    """Supprimer une image de la galerie."""
    permission_classes = [IsOpticienOuAdmin]

    def delete(self, request, pk, image_id):
        try:
            img = MontureImage.objects.get(pk=image_id, monture_id=pk)
        except MontureImage.DoesNotExist:
            return Response({'detail': 'Image introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        img.image.delete(save=False)  # Supprimer le fichier
        img.delete()
        return Response({'detail': 'Image supprimée.'})


class SupprimerImagePrincipale(APIView):
    """Supprimer l'image principale d'une monture."""
    permission_classes = [IsOpticienOuAdmin]

    def delete(self, request, pk):
        try:
            monture = Monture.objects.get(pk=pk)
        except Monture.DoesNotExist:
            return Response({'detail': 'Monture introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        if monture.image:
            monture.image.delete(save=False)
            monture.image = None
            monture.save(update_fields=['image'])

        return Response({'detail': 'Image principale supprimée.'})
