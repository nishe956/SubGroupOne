from rest_framework import generics, viewsets
from rest_framework.permissions import IsAuthenticated
from .models import Commande
from .serializers import CommandeSerializer
from users.permissions import IsAdminUserRole, IsOpticianUserRole, IsAdminOrOpticianRole

class CommandeListCreateView(generics.ListCreateAPIView):
    serializer_class = CommandeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Commande.objects.filter(user=self.request.user).order_by('-date_commande')

    def perform_create(self, serializer):
        from decimal import Decimal
        user = self.request.user
        monture = serializer.validated_data['monture']
        quantite = serializer.validated_data.get('quantite', 1)
        is_assurance_utilisee = serializer.validated_data.get('is_assurance_utilisee', False)
        
        # Nouvelles données d'achat familial
        nb_membres = serializer.validated_data.get('nb_membres_famille', 1)
        nb_lunettes = serializer.validated_data.get('nb_lunettes_famille', 1)
        
        prix_base = monture.prix * quantite
        remise_famille = Decimal('0')
        
        # 1. Nouveau Calcul Remise Famille Dynamique
        # On applique la remise si c'est un achat groupé (nb_lunettes > 1)
        if nb_lunettes > 1:
            # Règle : 10% de base + 5% par paire supplémentaire (max 25%)
            taux_remise = Decimal(str(min(0.10 + (nb_lunettes - 1) * 0.05, 0.25)))
            remise_famille = prix_base * taux_remise
        elif user.code_famille:
            # Fallback sur l'ancienne logique de code partagé si pas d'achat groupé déclaré
            from django.contrib.auth import get_user_model
            User = get_user_model()
            famille_members = User.objects.filter(code_famille=user.code_famille).exclude(id=user.id)
            if Commande.objects.filter(user__in=famille_members).exists():
                remise_famille = prix_base * Decimal('0.15')
        
        prix_apres_remise = prix_base - remise_famille
        part_assurance = Decimal('0')
        
        # 2. Calcul Part Assurance (80% du reste si activé et infos présentes)
        if is_assurance_utilisee and user.assurance_nom and user.assurance_numero:
            part_assurance = prix_apres_remise * Decimal('0.80')
            
        part_client = prix_apres_remise - part_assurance
        
        serializer.save(
            user=user, 
            prix_total=prix_base,
            remise_famille=remise_famille,
            part_assurance=part_assurance,
            part_client=part_client
        )

class CommandeDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = CommandeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Commande.objects.filter(user=self.request.user)

class OpticianCommandeViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour la gestion de toutes les commandes par l'opticien ou l'admin.
    """
    queryset = Commande.objects.get_queryset().order_by('-date_commande')
    serializer_class = CommandeSerializer
    permission_classes = [IsAdminOrOpticianRole]
