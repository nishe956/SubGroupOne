from rest_framework import generics, permissions
from rest_framework.response import Response
from .models import Monture
from .serializers import MontureSerializer

class IsOpticienOuAdmin(permissions.BasePermission):
    # Permission personnalisée : seuls opticiens et admins peuvent modifier
    def has_permission(self, request, view):
        if request.method in ['GET']:
            return True  # tout le monde peut voir les montures
        return request.user.is_authenticated and \
               request.user.role in ['opticien', 'admin']

class ListeMontures(generics.ListCreateAPIView):
    # GET → liste toutes les montures disponibles
    # POST → ajoute une nouvelle monture (opticien/admin)
    serializer_class = MontureSerializer
    permission_classes = [IsOpticienOuAdmin]

    def get_queryset(self):
        queryset = Monture.objects.filter(disponible=True)
        
        # Filtres optionnels dans l'URL
        # ex: /api/montures/?forme=ronde&couleur=noir
        forme = self.request.query_params.get('forme')
        couleur = self.request.query_params.get('couleur')
        marque = self.request.query_params.get('marque')
        
        if forme:
            queryset = queryset.filter(forme=forme)
        if couleur:
            queryset = queryset.filter(couleur__icontains=couleur)
        if marque:
            queryset = queryset.filter(marque__icontains=marque)
            
        return queryset

class DetailMonture(generics.RetrieveUpdateDestroyAPIView):
    # GET → voir une monture précise
    # PUT → modifier une monture
    # DELETE → supprimer une monture
    queryset = Monture.objects.all()
    serializer_class = MontureSerializer
    permission_classes = [IsOpticienOuAdmin]