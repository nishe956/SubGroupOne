from rest_framework import serializers
from .models import Ordonnance

class OrdonnanceSerializer(serializers.ModelSerializer):
    client_nom = serializers.CharField(
        source='client.username', 
        read_only=True
    )
    
    class Meta:
        model = Ordonnance
        fields = [
            'id', 'client', 'client_nom', 'image',
            'oeil_droit_sphere', 'oeil_droit_cylindre', 'oeil_droit_axe',
            'oeil_gauche_sphere', 'oeil_gauche_cylindre', 'oeil_gauche_axe',
            'date_upload', 'validee'
        ]
        read_only_fields = ['id', 'date_upload', 'client']