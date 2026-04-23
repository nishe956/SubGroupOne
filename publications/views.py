from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Publication, LikePublication, Commentaire
from .serializers import PublicationSerializer, CommentaireSerializer
from users.permissions import IsOpticienOuAdmin


class ListePublications(generics.ListAPIView):
    serializer_class    = PublicationSerializer
    permission_classes  = [permissions.AllowAny]

    def get_queryset(self):
        qs  = Publication.objects.filter(publie=True)
        q   = self.request.query_params.get('search')
        cat = self.request.query_params.get('categorie')
        if q:   qs = qs.filter(titre__icontains=q) | qs.filter(contenu__icontains=q)
        if cat: qs = qs.filter(categorie=cat)
        return qs


class CreerPublication(generics.CreateAPIView):
    serializer_class   = PublicationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(auteur=self.request.user, publie=True)


class DetailPublication(generics.RetrieveUpdateDestroyAPIView):
    queryset           = Publication.objects.all()
    serializer_class   = PublicationSerializer

    def get_permissions(self):
        if self.request.method == 'GET':
            return [permissions.AllowAny()]
        return [IsOpticienOuAdmin()]

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.vues += 1
        instance.save(update_fields=['vues'])
        return super().retrieve(request, *args, **kwargs)


class LikerPublication(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        pub  = Publication.objects.get(pk=pk)
        like, created = LikePublication.objects.get_or_create(publication=pub, user=request.user)
        if not created:
            like.delete()
            return Response({'liked': False, 'likes': pub.likes_set.count()})
        return Response({'liked': True, 'likes': pub.likes_set.count()})


class CommenterPublication(generics.CreateAPIView):
    serializer_class   = CommentaireSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        pub = Publication.objects.get(pk=self.kwargs['pk'])
        serializer.save(auteur=self.request.user, publication=pub)
