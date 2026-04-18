from rest_framework import generics, filters
from rest_framework.permissions import IsAuthenticatedOrReadOnly
from .models import Monture
from .serializers import MontureSerializer

class MontureListView(generics.ListCreateAPIView):
    queryset = Monture.objects.filter(disponible=True)
    serializer_class = MontureSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['nom', 'marque', 'couleur']
    ordering_fields = ['prix', 'date_ajout']

    def get_queryset(self):
        user = self.request.user
        if user and user.is_authenticated and user.role in ['admin', 'opticien']:
            qs = Monture.objects.all()
        else:
            qs = Monture.objects.filter(disponible=True)

        genre = self.request.query_params.get('genre')
        forme = self.request.query_params.get('forme')
        if genre:
            qs = qs.filter(genre=genre)
        if forme:
            qs = qs.filter(forme=forme)
        return qs

class MontureDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Monture.objects.all()
    serializer_class = MontureSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
