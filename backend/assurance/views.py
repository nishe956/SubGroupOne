from decimal import Decimal, InvalidOperation

from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from users.permissions import CompteUtilisable, IsAdminSeulement
from utils.audit import journaliser

from .models import CompagnieAssurance, DemandeRemboursement
from .serializers import CompagnieAssuranceSerializer, DemandeRemboursementSerializer

# Statuts d'une commande à partir desquels un remboursement peut être demandé.
STATUTS_ELIGIBLES = ('validee', 'en_preparation', 'expediee', 'livree')


class ListeCompagnies(generics.ListCreateAPIView):
    """Lecture publique du catalogue ; création réservée à l'administration.

    Le taux de prise en charge pilote directement les montants remboursés : un
    opticien ne doit pas pouvoir créer une compagnie ni fixer son taux.
    """
    serializer_class = CompagnieAssuranceSerializer

    def get_permissions(self):
        if self.request.method == 'GET':
            return [permissions.AllowAny()]
        return [IsAdminSeulement()]

    def get_queryset(self):
        return CompagnieAssurance.objects.filter(active=True).order_by('nom')

    def perform_create(self, serializer):
        compagnie = serializer.save()
        journaliser('compagnie_creee', self.request.user,
                    compagnie_id=compagnie.pk, taux=str(compagnie.taux_prise_charge))


class DetailCompagnie(generics.RetrieveUpdateDestroyAPIView):
    queryset = CompagnieAssurance.objects.all()
    serializer_class = CompagnieAssuranceSerializer
    permission_classes = [IsAdminSeulement]

    def perform_update(self, serializer):
        compagnie = serializer.save()
        journaliser('compagnie_modifiee', self.request.user,
                    compagnie_id=compagnie.pk, taux=str(compagnie.taux_prise_charge))

    def perform_destroy(self, instance):
        journaliser('compagnie_supprimee', self.request.user, compagnie_id=instance.pk)
        super().perform_destroy(instance)


class SimulerRemboursement(APIView):
    """Calcule le montant remboursé avant de soumettre la demande.

    Purement informatif : le montant réellement enregistré est toujours recalculé
    depuis la commande (voir MesDemandesRemboursement).
    """
    permission_classes = [CompteUtilisable]

    def post(self, request):
        compagnie_id = request.data.get('compagnie_id')
        try:
            montant = Decimal(str(request.data.get('montant', '0')))
        except (InvalidOperation, TypeError, ValueError):
            return Response({'detail': 'Montant invalide.'}, status=status.HTTP_400_BAD_REQUEST)

        if montant < 0:
            return Response({'detail': 'Montant invalide.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            compagnie = CompagnieAssurance.objects.get(pk=compagnie_id, active=True)
        except (CompagnieAssurance.DoesNotExist, ValueError, TypeError):
            return Response({'detail': 'Compagnie introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        rembourse = montant * (compagnie.taux_prise_charge / Decimal('100'))
        if compagnie.plafond_annuel:
            rembourse = min(rembourse, compagnie.plafond_annuel)
        patient = montant - rembourse

        return Response({
            'compagnie':         compagnie.nom,
            'taux':              float(compagnie.taux_prise_charge),
            'montant_total':     float(montant),
            'montant_rembourse': float(round(rembourse, 2)),
            'montant_patient':   float(round(patient, 2)),
            'plafond_annuel':    float(compagnie.plafond_annuel) if compagnie.plafond_annuel else None,
        })


class MesDemandesRemboursement(generics.ListCreateAPIView):
    serializer_class = DemandeRemboursementSerializer
    permission_classes = [CompteUtilisable]

    def get_queryset(self):
        user = self.request.user
        qs = DemandeRemboursement.objects.select_related('commande', 'compagnie', 'client')
        if user.role == 'admin':
            return qs.all()
        if user.role == 'opticien':
            # Un opticien voyait auparavant toutes les demandes du réseau ;
            # il ne doit voir que celles issues de ses propres ventes.
            return qs.filter(commande__opticien=user)
        return qs.filter(client=user)

    def perform_create(self, serializer):
        user = self.request.user
        commande = serializer.validated_data.get('commande')

        # 1. La commande doit exister ET appartenir au demandeur.
        #    Sans ce contrôle, `commande` étant un champ libre du sérialiseur,
        #    n'importe qui pouvait créer une demande sur la commande d'un tiers.
        if commande is None or commande.client_id != user.id:
            raise ValidationError({'commande': "Cette commande ne vous appartient pas."})

        # 2. Elle doit être dans un état qui justifie un remboursement.
        if commande.statut not in STATUTS_ELIGIBLES:
            raise ValidationError(
                {'commande': "Cette commande n'est pas éligible à un remboursement."}
            )

        # 3. Une seule demande par commande (la contrainte OneToOne existe déjà en
        #    base, mais on renvoie une erreur métier plutôt qu'une 500).
        if DemandeRemboursement.objects.filter(commande=commande).exists():
            raise ValidationError({'commande': "Une demande existe déjà pour cette commande."})

        compagnie = serializer.validated_data.get('compagnie')
        if compagnie is None or not compagnie.active:
            raise ValidationError({'compagnie': "Compagnie d'assurance invalide."})

        # 4. Le montant vient de la commande, jamais de la requête : `montant_total`
        #    était modifiable, ce qui permettait de réclamer un montant arbitraire.
        demande = DemandeRemboursement(
            commande=commande,
            compagnie=compagnie,
            client=user,
            numero_police=serializer.validated_data.get('numero_police', '')[:100],
            montant_total=commande.prix_total,
        )
        demande.calculer_montants()
        demande.save()
        serializer.instance = demande

        journaliser('demande_remboursement', user, demande_id=demande.pk,
                    commande_id=commande.pk, montant=str(demande.montant_total))


class TraiterDemande(APIView):
    """Seul l'admin approuve/rejette une demande de remboursement (enjeu financier)."""
    permission_classes = [IsAdminSeulement]

    STATUTS_VALIDES = ('soumise', 'approuvee', 'rejetee', 'remboursee')

    def post(self, request, pk):
        try:
            demande = DemandeRemboursement.objects.get(pk=pk)
        except DemandeRemboursement.DoesNotExist:
            return Response({'detail': 'Demande introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        statut = request.data.get('statut')
        if statut not in self.STATUTS_VALIDES:
            return Response(
                {'detail': f'Statut invalide. Options : {list(self.STATUTS_VALIDES)}'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Un remboursement déjà versé ne se rejoue pas.
        if demande.statut == 'remboursee':
            return Response(
                {'detail': 'Cette demande a déjà été remboursée.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        ancien = demande.statut
        demande.statut = statut
        demande.notes = str(request.data.get('notes', demande.notes))[:2000]
        if statut in ('approuvee', 'remboursee', 'rejetee'):
            demande.date_traitement = timezone.now()
        demande.save()

        journaliser('remboursement_traite', request.user, demande_id=demande.pk,
                    ancien=ancien, nouveau=statut, montant=str(demande.montant_rembourse))

        return Response(DemandeRemboursementSerializer(demande).data)
