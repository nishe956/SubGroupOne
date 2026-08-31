from django.db.models import Q
from rest_framework import generics, permissions, status
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from rest_framework.views import APIView

from users.permissions import IsOpticienOuAdmin
from utils.audit import journaliser
from utils.validators import valider_image_seulement

from .models import Monture, MontureImage
from .serializers import MontureImageSerializer, MontureSerializer

# Nombre maximal d'images dans la galerie d'une monture.
MAX_IMAGES_GALERIE = 10


def _monture_modifiable(user, pk):
    """Retourne la monture si l'utilisateur a le droit de la modifier.

    Ce contrôle manquait sur l'ajustement de stock et la gestion des images :
    tout opticien pouvait mettre à zéro le stock d'un concurrent ou supprimer
    ses visuels produit.
    """
    monture = Monture.objects.filter(pk=pk).first()
    if monture is None:
        return None, Response(
            {'detail': 'Monture introuvable.'}, status=status.HTTP_404_NOT_FOUND
        )
    if user.role != 'admin' and monture.ajoute_par_id != user.id:
        return None, Response(
            {'detail': 'Vous ne pouvez modifier que vos propres montures.'},
            status=status.HTTP_403_FORBIDDEN,
        )
    return monture, None


class ListeMontures(generics.ListCreateAPIView):
    serializer_class = MontureSerializer

    def get_permissions(self):
        if self.request.method == 'GET':
            return [permissions.AllowAny()]
        return [IsOpticienOuAdmin()]

    def get_queryset(self):
        params = self.request.query_params
        qs = Monture.objects.select_related('ajoute_par').prefetch_related('galerie')

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
        type_     = params.get('type')
        prix_min  = params.get('prix_min') or params.get('minPrix')
        prix_max  = params.get('prix_max') or params.get('maxPrix')
        sort      = params.get('sort', '-date_ajout')

        # Parcours "vue" : montures correctrices (vue + mixte).
        # Parcours "solaire" : montures de style (solaire + mixte).
        if type_ == 'vue':
            qs = qs.filter(type__in=['vue', 'mixte'])
        elif type_ == 'solaire':
            qs = qs.filter(type__in=['solaire', 'mixte'])

        if forme:     qs = qs.filter(forme=forme)
        if couleur:   qs = qs.filter(couleur__icontains=couleur[:50])
        if marque:    qs = qs.filter(marque__icontains=marque[:100])
        if categorie: qs = qs.filter(categorie=categorie)
        if search:
            terme = search[:100]
            qs = qs.filter(Q(nom__icontains=terme) | Q(marque__icontains=terme))

        # Les bornes de prix arrivent du client : une valeur non numérique
        # provoquait une 500 au moment de l'évaluation du queryset.
        for valeur, filtre in ((prix_min, 'prix__gte'), (prix_max, 'prix__lte')):
            if valeur:
                try:
                    qs = qs.filter(**{filtre: float(valeur)})
                except (TypeError, ValueError):
                    pass

        valid_sorts = ['prix', '-prix', 'date_ajout', '-date_ajout', 'nom', '-nom']
        return qs.order_by(sort if sort in valid_sorts else '-date_ajout')

    def perform_create(self, serializer):
        """Enregistre automatiquement l'opticien qui ajoute la monture."""
        image = self.request.FILES.get('image')
        if image:
            valider_image_seulement(image)
        stock = serializer.validated_data.get('stock', 0)
        monture = serializer.save(ajoute_par=self.request.user, disponible=stock > 0)
        journaliser('monture_creee', self.request.user, monture_id=monture.pk)


class DetailMonture(generics.RetrieveUpdateDestroyAPIView):
    queryset = Monture.objects.select_related('ajoute_par').prefetch_related('galerie')
    serializer_class = MontureSerializer

    def get_permissions(self):
        if self.request.method == 'GET':
            return [permissions.AllowAny()]
        return [IsOpticienOuAdmin()]

    def check_object_permissions(self, request, obj):
        super().check_object_permissions(request, obj)
        # Un opticien ne peut modifier/supprimer QUE ses propres montures.
        if request.method not in permissions.SAFE_METHODS:
            if request.user.role == 'opticien' and obj.ajoute_par_id != request.user.id:
                raise PermissionDenied("Vous ne pouvez modifier que vos propres montures.")

    def perform_update(self, serializer):
        image = self.request.FILES.get('image')
        if image:
            valider_image_seulement(image)
        serializer.save()


class UpdateStockMonture(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def patch(self, request, pk):
        monture, erreur = _monture_modifiable(request.user, pk)
        if erreur:
            return erreur

        try:
            stock = int(request.data.get('stock'))
        except (TypeError, ValueError):
            return Response(
                {'detail': 'Le champ stock doit être un entier.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if stock < 0:
            return Response(
                {'detail': 'Le stock ne peut pas être négatif.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        ancien = monture.stock
        monture.stock = stock
        monture.disponible = stock > 0
        monture.save(update_fields=['stock', 'disponible'])
        journaliser('stock_modifie', request.user, monture_id=monture.pk,
                    ancien=ancien, nouveau=stock)
        return Response(MontureSerializer(monture).data)


class RecommenderMontures(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        # Recommandations basées sur l'ordonnance ou les préférences
        forme_visage = request.data.get('forme_visage')

        qs = Monture.objects.filter(disponible=True, stock__gt=0)

        # Règles de recommandation selon forme du visage
        correspondances = {
            'ovale': ['ronde', 'carree', 'rectangulaire'],
            'rond':  ['rectangulaire', 'carree'],
            'carre': ['ronde', 'ovale'],
            'coeur': ['ronde', 'ovale'],
        }
        if forme_visage in correspondances:
            qs = qs.filter(forme__in=correspondances[forme_visage])

        return Response(MontureSerializer(qs[:8], many=True).data)


class AjouterImage(APIView):
    """Ajouter une image à la galerie d'une monture."""
    permission_classes = [IsOpticienOuAdmin]

    def post(self, request, pk):
        monture, erreur = _monture_modifiable(request.user, pk)
        if erreur:
            return erreur

        image = request.FILES.get('image')
        if not image:
            return Response({'detail': 'Image requise.'}, status=status.HTTP_400_BAD_REQUEST)

        valider_image_seulement(image)

        ordre = MontureImage.objects.filter(monture=monture).count()
        if ordre >= MAX_IMAGES_GALERIE:
            return Response(
                {'detail': f'Maximum {MAX_IMAGES_GALERIE} images par monture.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        img = MontureImage.objects.create(monture=monture, image=image, ordre=ordre)

        # Si c'est la première image galerie, mettre aussi comme image principale
        if not monture.image:
            monture.image = img.image
            monture.save(update_fields=['image'])

        return Response(MontureImageSerializer(img).data, status=status.HTTP_201_CREATED)


class SupprimerImage(APIView):
    """Supprimer une image de la galerie."""
    permission_classes = [IsOpticienOuAdmin]

    def delete(self, request, pk, image_id):
        monture, erreur = _monture_modifiable(request.user, pk)
        if erreur:
            return erreur

        img = MontureImage.objects.filter(pk=image_id, monture=monture).first()
        if img is None:
            return Response({'detail': 'Image introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        img.image.delete(save=False)  # Supprimer le fichier
        img.delete()
        return Response({'detail': 'Image supprimée.'})


class SupprimerImagePrincipale(APIView):
    """Supprimer l'image principale d'une monture."""
    permission_classes = [IsOpticienOuAdmin]

    def delete(self, request, pk):
        monture, erreur = _monture_modifiable(request.user, pk)
        if erreur:
            return erreur

        if monture.image:
            monture.image.delete(save=False)
            monture.image = None
            monture.save(update_fields=['image'])

        return Response({'detail': 'Image principale supprimée.'})
