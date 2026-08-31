from django.db.models import F, Q
from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions, status
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from rest_framework.views import APIView

from users.permissions import CompteUtilisable, IsOpticienOuAdmin
from utils.validators import valider_image_seulement

from .models import Commentaire, LikePublication, Publication
from .serializers import CommentaireSerializer, PublicationSerializer

LONGUEUR_MAX_COMMENTAIRE = 2000


class ListePublications(generics.ListAPIView):
    serializer_class = PublicationSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = Publication.objects.filter(publie=True).select_related('auteur')
        q = self.request.query_params.get('search')
        cat = self.request.query_params.get('categorie')
        if q:
            terme = q[:100]
            qs = qs.filter(Q(titre__icontains=terme) | Q(contenu__icontains=terme))
        if cat:
            qs = qs.filter(categorie=cat)
        return qs


class CreerPublication(generics.CreateAPIView):
    serializer_class = PublicationSerializer
    # Auparavant ouvert à tout utilisateur authentifié, avec `publie=True` forcé :
    # n'importe quel client pouvait publier du contenu sur le site public.
    permission_classes = [IsOpticienOuAdmin]

    def perform_create(self, serializer):
        image = self.request.FILES.get('image')
        if image:
            valider_image_seulement(image)
        # Publication soumise à validation : seul un admin peut publier
        # directement, un opticien crée un brouillon.
        publie = self.request.user.role == 'admin'
        serializer.save(auteur=self.request.user, publie=publie)


class DetailPublication(generics.RetrieveUpdateDestroyAPIView):
    queryset = Publication.objects.select_related('auteur')
    serializer_class = PublicationSerializer

    def get_permissions(self):
        if self.request.method in permissions.SAFE_METHODS:
            return [permissions.AllowAny()]
        return [IsOpticienOuAdmin()]

    def get_object(self):
        obj = super().get_object()
        # Un brouillon n'est visible que de son auteur et des admins.
        if not obj.publie:
            user = self.request.user
            if not user.is_authenticated or (
                user.role != 'admin' and obj.auteur_id != user.id
            ):
                from django.http import Http404
                raise Http404
        return obj

    def check_object_permissions(self, request, obj):
        super().check_object_permissions(request, obj)
        # Un opticien ne modifie/supprime que ses propres publications.
        if request.method not in permissions.SAFE_METHODS:
            if request.user.role != 'admin' and obj.auteur_id != request.user.id:
                raise PermissionDenied("Vous ne pouvez modifier que vos propres publications.")

    def perform_update(self, serializer):
        image = self.request.FILES.get('image')
        if image:
            valider_image_seulement(image)
        serializer.save()

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        # Incrément atomique, sans relire l'objet : `instance.vues += 1` perdait
        # des vues en cas de requêtes concurrentes.
        Publication.objects.filter(pk=instance.pk).update(vues=F('vues') + 1)
        return super().retrieve(request, *args, **kwargs)


class LikerPublication(APIView):
    permission_classes = [CompteUtilisable]

    def post(self, request, pk):
        # `Publication.objects.get(pk=pk)` levait une 500 sur un identifiant inconnu.
        pub = get_object_or_404(Publication, pk=pk, publie=True)
        like, created = LikePublication.objects.get_or_create(publication=pub, user=request.user)
        if not created:
            like.delete()
            return Response({'liked': False, 'likes': pub.likes_set.count()})
        return Response({'liked': True, 'likes': pub.likes_set.count()})


class CommenterPublication(generics.CreateAPIView):
    serializer_class = CommentaireSerializer
    permission_classes = [CompteUtilisable]

    def create(self, request, *args, **kwargs):
        contenu = (request.data.get('contenu') or '').strip()
        if not contenu:
            return Response(
                {'contenu': 'Le commentaire ne peut pas être vide.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if len(contenu) > LONGUEUR_MAX_COMMENTAIRE:
            return Response(
                {'contenu': f'Commentaire trop long (maximum {LONGUEUR_MAX_COMMENTAIRE} caractères).'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return super().create(request, *args, **kwargs)

    def perform_create(self, serializer):
        pub = get_object_or_404(Publication, pk=self.kwargs['pk'], publie=True)
        serializer.save(auteur=self.request.user, publication=pub)
