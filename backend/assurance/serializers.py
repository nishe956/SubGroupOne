from rest_framework import serializers
from .models import CompagnieAssurance, DemandeRemboursement


class CompagnieAssuranceSerializer(serializers.ModelSerializer):
    class Meta:
        model  = CompagnieAssurance
        fields = [
            'id', 'nom', 'code', 'taux_prise_charge', 'plafond_annuel',
            'telephone', 'email', 'adresse', 'active',
        ]


class DemandeRemboursementSerializer(serializers.ModelSerializer):
    compagnie_nom   = serializers.CharField(source='compagnie.nom', read_only=True)
    compagnie_taux  = serializers.DecimalField(source='compagnie.taux_prise_charge', max_digits=5, decimal_places=2, read_only=True)
    commande_ref    = serializers.IntegerField(source='commande.id', read_only=True)

    class Meta:
        model  = DemandeRemboursement
        fields = [
            'id', 'commande', 'commande_ref', 'compagnie', 'compagnie_nom',
            'compagnie_taux', 'client', 'numero_police',
            'montant_total', 'montant_rembourse', 'montant_patient',
            'statut', 'date_soumission', 'date_traitement', 'notes',
        ]
        read_only_fields = ['id', 'client', 'montant_rembourse', 'montant_patient', 'date_soumission']
