from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Commande
from .serializers import CommandeSerializer

class PasserCommande(generics.CreateAPIView):
    # POST → client passe une commande
    serializer_class = CommandeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        monture = serializer.validated_data['monture']
        serializer.save(
            client=self.request.user,
            prix_total=monture.prix
        )

class ListeCommandes(generics.ListAPIView):
    # GET → liste les commandes
    serializer_class = CommandeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        # Client voit seulement ses commandes
        if user.role == 'client':
            return Commande.objects.filter(client=user)
        # Opticien et admin voient toutes les commandes
        return Commande.objects.all()

class DetailCommande(generics.RetrieveAPIView):
    # GET → voir le détail d'une commande
    serializer_class = CommandeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'client':
            return Commande.objects.filter(client=user)
        return Commande.objects.all()

class GererCommande(APIView):
    # POST → opticien valide ou rejette une commande
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        if request.user.role not in ['opticien', 'admin']:
            return Response(
                {'erreur': 'Permission refusée'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            commande = Commande.objects.get(pk=pk)
        except Commande.DoesNotExist:
            return Response(
                {'erreur': 'Commande introuvable'},
                status=status.HTTP_404_NOT_FOUND
            )

        nouveau_statut = request.data.get('statut')
        statuts_valides = ['validee', 'rejetee', 'en_preparation', 'livree']
        
        if nouveau_statut not in statuts_valides:
            return Response(
                {'erreur': f'Statut invalide. Choisir parmi : {statuts_valides}'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        commande.statut = nouveau_statut
        commande.notes = request.data.get('notes', commande.notes)
        commande.save()
        
        return Response({
            'message': f'Commande {nouveau_statut} avec succès',
            'commande': CommandeSerializer(commande).data
        })