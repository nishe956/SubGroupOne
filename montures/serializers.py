from rest_framework import serializers
from .models import Monture

class MontureSerializer(serializers.ModelSerializer):
    class Meta:
        model = Monture
        fields = [
            'id', 'nom', 'marque', 'prix', 'forme', 
            'couleur', 'image', 'description', 
            'stock', 'disponible', 'date_ajout'
        ]
        read_only_fields = ['id', 'date_ajout']