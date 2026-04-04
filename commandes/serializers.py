from rest_framework import serializers
from .models import Commande
from montures.serializers import MontureSerializer

class CommandeSerializer(serializers.ModelSerializer):
    client_nom = serializers.CharField(
        source='client.username', 
        read_only=True
    )
    monture_detail = MontureSerializer(
        source='monture', 
        read_only=True
    )

    class Meta:
        model = Commande
        fields = [
            'id', 'client', 'client_nom', 
            'monture', 'monture_detail',
            'ordonnance', 'statut',
            'numero_assurance', 'nom_assurance',
            'prix_total', 'date_commande', 
            'date_mise_a_jour', 'notes'
        ]
        read_only_fields = [
            'id', 'client', 'date_commande', 
            'date_mise_a_jour', 'statut',
            'prix_total'  # ← ajouté ici, calculé automatiquement
        ]