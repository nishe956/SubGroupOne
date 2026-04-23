from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.utils import timezone
from .models import CompagnieAssurance, DemandeRemboursement
from .serializers import CompagnieAssuranceSerializer, DemandeRemboursementSerializer
from users.permissions import IsOpticienOuAdmin


class ListeCompagnies(generics.ListCreateAPIView):
    serializer_class = CompagnieAssuranceSerializer

    def get_permissions(self):
        if self.request.method == 'GET':
            return [permissions.AllowAny()]
        return [IsOpticienOuAdmin()]

    def get_queryset(self):
        return CompagnieAssurance.objects.filter(active=True)


class DetailCompagnie(generics.RetrieveUpdateDestroyAPIView):
    queryset           = CompagnieAssurance.objects.all()
    serializer_class   = CompagnieAssuranceSerializer
    permission_classes = [IsOpticienOuAdmin]


class SimulerRemboursement(APIView):
    """Calcule le montant remboursé avant de soumettre la demande."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        compagnie_id = request.data.get('compagnie_id')
        montant      = float(request.data.get('montant', 0))

        try:
            compagnie = CompagnieAssurance.objects.get(pk=compagnie_id, active=True)
        except CompagnieAssurance.DoesNotExist:
            return Response({'detail': 'Compagnie introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        taux = float(compagnie.taux_prise_charge) / 100
        rembourse = montant * taux
        if compagnie.plafond_annuel:
            rembourse = min(rembourse, float(compagnie.plafond_annuel))
        patient = montant - rembourse

        return Response({
            'compagnie':          compagnie.nom,
            'taux':               float(compagnie.taux_prise_charge),
            'montant_total':      montant,
            'montant_rembourse':  round(rembourse, 2),
            'montant_patient':    round(patient, 2),
            'plafond_annuel':     float(compagnie.plafond_annuel) if compagnie.plafond_annuel else None,
        })


class MesDemandesRemboursement(generics.ListCreateAPIView):
    serializer_class   = DemandeRemboursementSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role in ['admin', 'opticien']:
            return DemandeRemboursement.objects.all()
        return DemandeRemboursement.objects.filter(client=user)

    def perform_create(self, serializer):
        compagnie = serializer.validated_data.get('compagnie')
        montant   = float(serializer.validated_data.get('montant_total', 0))

        rembourse = 0
        patient   = montant
        if compagnie:
            taux = float(compagnie.taux_prise_charge) / 100
            rembourse = montant * taux
            if compagnie.plafond_annuel:
                rembourse = min(rembourse, float(compagnie.plafond_annuel))
            patient = montant - rembourse

        serializer.save(
            client=self.request.user,
            montant_rembourse=round(rembourse, 2),
            montant_patient=round(patient, 2),
        )


class TraiterDemande(APIView):
    """Opticien/Admin met à jour le statut d'une demande."""
    permission_classes = [IsOpticienOuAdmin]

    def post(self, request, pk):
        try:
            demande = DemandeRemboursement.objects.get(pk=pk)
        except DemandeRemboursement.DoesNotExist:
            return Response({'detail': 'Demande introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        statut = request.data.get('statut')
        statuts_valides = ['soumise', 'approuvee', 'rejetee', 'remboursee']
        if statut not in statuts_valides:
            return Response({'detail': f'Statut invalide. Options : {statuts_valides}'}, status=status.HTTP_400_BAD_REQUEST)

        demande.statut = statut
        demande.notes  = request.data.get('notes', demande.notes)
        if statut in ['approuvee', 'remboursee', 'rejetee']:
            demande.date_traitement = timezone.now()
        demande.save()

        return Response(DemandeRemboursementSerializer(demande).data)
