from rest_framework import status, generics
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.contrib.auth import authenticate, get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from .serializers import UserSerializer, RegisterSerializer
from .permissions import IsAdminUserRole, IsAdminOrOpticianRole

User = get_user_model()

class RegisterView(generics.CreateAPIView):
    permission_classes = [AllowAny]
    serializer_class = RegisterSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response({
            'user': UserSerializer(user).data,
            'refresh': str(refresh),
            'access': str(refresh.access_token),
        }, status=status.HTTP_201_CREATED)

class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')
        password = request.data.get('password')
        
        user = authenticate(email=email, password=password)
        if user is None:
            return Response({'error': 'Identifiants invalides.'}, status=status.HTTP_401_UNAUTHORIZED)
            
        refresh = RefreshToken.for_user(user)
        return Response({
            'user': UserSerializer(user).data,
            'refresh': str(refresh),
            'access': str(refresh.access_token),
        })


class ProfileView(generics.RetrieveUpdateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user

class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        old_password = request.data.get('old_password')
        new_password = request.data.get('new_password')
        if not user.check_password(old_password):
            return Response({'error': 'Ancien mot de passe incorrect.'}, status=status.HTTP_400_BAD_REQUEST)
        user.set_password(new_password)
        user.save()
        return Response({'message': 'Mot de passe mis à jour avec succès.'})

from rest_framework import viewsets, filters
from .serializers import (
    UserSerializer, RegisterSerializer, UserAdminSerializer, 
    PartnerAssuranceSerializer, AuditLogSerializer
)
from .models import PartnerAssurance, AuditLog
from commandes.models import Commande
from montures.models import Monture
from django.db.models import Sum, Count

class UserManagementViewSet(viewsets.ModelViewSet):
    """Gestion des clients et opticiens par l'Admin."""
    queryset = User.objects.all().order_by('-date_joined')
    serializer_class = UserAdminSerializer
    permission_classes = [IsAdminUserRole]
    filter_backends = [filters.SearchFilter]
    search_fields = ['email', 'first_name', 'last_name', 'role']

    def perform_create(self, serializer):
        user = serializer.save()
        AuditLog.objects.create(
            user=self.request.user,
            action="Création d'utilisateur",
            details=f"Utilisateur {user.email} créé avec le rôle {user.role}"
        )

    def perform_update(self, serializer):
        user = serializer.save()
        AuditLog.objects.create(
            user=self.request.user,
            action="Modification d'utilisateur",
            details=f"Utilisateur {user.email} mis à jour (Actif: {user.is_active}, Rôle: {user.role})"
        )

    def perform_destroy(self, instance):
        email = instance.email
        instance.delete()
        AuditLog.objects.create(
            user=self.request.user,
            action="Suppression d'utilisateur",
            details=f"Utilisateur {email} supprimé par l'administrateur"
        )

class PartnerAssuranceViewSet(viewsets.ModelViewSet):
    """Gestion des assurances partenaires par l'Admin."""
    queryset = PartnerAssurance.objects.all()
    serializer_class = PartnerAssuranceSerializer
    permission_classes = [IsAdminUserRole]

    def perform_create(self, serializer):
        assurance = serializer.save()
        AuditLog.objects.create(
            user=self.request.user,
            action="Ajout d'assurance",
            details=f"Partenaire {assurance.nom} ajouté"
        )

    def perform_destroy(self, instance):
        nom = instance.nom
        instance.delete()
        AuditLog.objects.create(
            user=self.request.user,
            action="Suppression d'assurance",
            details=f"Partenaire {nom} retiré"
        )

class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    """Consultation des logs système par l'Admin."""
    queryset = AuditLog.objects.all()
    serializer_class = AuditLogSerializer
    permission_classes = [IsAdminUserRole]

class StatisticsView(APIView):
    """Statistiques globales pour l'Admin et l'Opticien."""
    permission_classes = [IsAdminOrOpticianRole]

    def get(self, request):
        from montures.models import Monture
        from commandes.models import Commande
        from ordonnances.models import Ordonnance
        
        if request.user.role == 'admin':
            stats = {
                'total_revenue': float(Commande.objects.filter(statut='livrer').aggregate(Sum('prix_total'))['prix_total__sum'] or 0.0),
                'total_orders': Commande.objects.count(),
                'total_clients': User.objects.filter(role='client').count(),
                'total_opticians': User.objects.filter(role='opticien').count(),
                'total_products': Monture.objects.count(),
                'total_prescriptions': Ordonnance.objects.count(),
                'recent_orders': Commande.objects.order_by('-date_commande')[:5].values('id', 'user__email', 'prix_total', 'statut'),
            }
        else:
            stats = {
                'products': Monture.objects.count(),
                'orders': Commande.objects.filter(user=request.user).count() if request.user.role == 'client' else Commande.objects.count(),
                'prescriptions': Ordonnance.objects.count(),
                'clients': User.objects.filter(role='client').count(),
            }
        return Response(stats)

from rest_framework.decorators import action
from .models import Notification
from .serializers import NotificationSerializer

class NotificationViewSet(viewsets.ModelViewSet):
    """Accès aux notifications sécurisé par utilisateur."""
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)

    @action(detail=True, methods=['patch'])
    def mark_read(self, request, pk=None):
        notification = self.get_object()
        notification.is_read = True
        notification.save()
        return Response({'status': 'notification marked as read'})
