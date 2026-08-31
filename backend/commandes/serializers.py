from rest_framework import serializers
from .models import Commande
from montures.serializers import MontureSerializer
from ordonnances.serializers import OrdonnanceSerializer

class CommandeSerializer(serializers.ModelSerializer):
    client_nom = serializers.CharField(
        source='client.username',
        read_only=True
    )
    monture_detail = MontureSerializer(
        source='monture',
        read_only=True
    )
    # Détail de l'ordonnance visible par l'opticien pour fabriquer les verres.
    ordonnance_detail = OrdonnanceSerializer(
        source='ordonnance',
        read_only=True
    )

    class Meta:
        model = Commande
        fields = [
            'id', 'client', 'client_nom',
            'monture', 'monture_detail',
            'ordonnance', 'ordonnance_detail', 'statut',
            'type_commande',
            'numero_assurance', 'nom_assurance',
            'methode_paiement', 'telephone_paiement',
            'adresse_livraison', 'latitude', 'longitude',
            'type_verre', 'options_verres', 'conception_verres', 'prix_verres',
            'prix_total', 'date_commande',
            'date_mise_a_jour', 'notes'
        ]
        # Tous les champs monétaires sont en lecture seule : ils sont calculés
        # par commandes.tarifs à partir d'identifiants, jamais reçus du client.
        read_only_fields = [
            'id', 'client', 'date_commande',
            'date_mise_a_jour', 'statut',
            'prix_total', 'prix_verres', 'notes',
        ]

    def validate(self, attrs):
        # Pour une commande de lunettes de vue, l'ordonnance est obligatoire.
        type_commande = attrs.get('type_commande', 'vue')
        if type_commande == 'vue' and not attrs.get('ordonnance'):
            raise serializers.ValidationError({
                'ordonnance': "Une ordonnance est obligatoire pour des lunettes de vue."
            })
        return attrs