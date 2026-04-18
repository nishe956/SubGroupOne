from rest_framework import serializers
from .models import Commande

class CommandeSerializer(serializers.ModelSerializer):
    user_email = serializers.SerializerMethodField()
    monture_nom = serializers.SerializerMethodField()

    def get_user_email(self, obj):
        return obj.user.email if obj.user else "Utilisateur Inconnu"

    def get_monture_nom(self, obj):
        return obj.monture.nom if obj.monture else "Produit Supprimé"

    class Meta:
        model = Commande
        fields = [
            'id', 'user', 'user_email', 'monture', 'monture_nom', 'quantite', 
            'prix_total', 'part_assurance', 'part_client', 'remise_famille',
            'is_assurance_utilisee', 'statut', 'date_commande', 'adresse_livraison', 
            'notes', 'type_livraison', 'mode_paiement', 'nb_membres_famille', 'nb_lunettes_famille'
        ]
        read_only_fields = ['user', 'prix_total', 'part_assurance', 'part_client', 'remise_famille', 'date_commande']
