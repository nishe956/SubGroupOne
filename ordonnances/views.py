from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Ordonnance
from .serializers import OrdonnanceSerializer

class AjouterOrdonnance(generics.CreateAPIView):
    # POST → client uploade son ordonnance
    serializer_class = OrdonnanceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        # Associe automatiquement l'ordonnance au client connecté
        serializer.save(client=self.request.user)

class ListeOrdonnances(generics.ListAPIView):
    # GET → liste les ordonnances
    serializer_class = OrdonnanceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        # Client voit seulement ses ordonnances
        # Opticien et admin voient toutes les ordonnances
        if user.role == 'client':
            return Ordonnance.objects.filter(client=user)
        return Ordonnance.objects.all()

class DetailOrdonnance(generics.RetrieveUpdateDestroyAPIView):
    # GET → voir une ordonnance
    # PUT → modifier/valider une ordonnance
    # DELETE → supprimer une ordonnance
    serializer_class = OrdonnanceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'client':
            return Ordonnance.objects.filter(client=user)
        return Ordonnance.objects.all()

class ValiderOrdonnance(APIView):
    # POST → opticien valide une ordonnance
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        if request.user.role not in ['opticien', 'admin']:
            return Response(
                {'erreur': 'Permission refusée'},
                status=status.HTTP_403_FORBIDDEN
            )
        try:
            ordonnance = Ordonnance.objects.get(pk=pk)
            ordonnance.validee = True
            ordonnance.save()
            return Response({'message': 'Ordonnance validée avec succès'})
        except Ordonnance.DoesNotExist:
            return Response(
                {'erreur': 'Ordonnance introuvable'},
                status=status.HTTP_404_NOT_FOUND
            )