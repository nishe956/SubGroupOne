from rest_framework import serializers
from .models import Monture, MontureImage


class MontureImageSerializer(serializers.ModelSerializer):
    class Meta:
        model  = MontureImage
        fields = ['id', 'image', 'ordre']


class MontureSerializer(serializers.ModelSerializer):
    galerie         = MontureImageSerializer(many=True, read_only=True)
    ajoute_par_nom  = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model  = Monture
        fields = [
            'id', 'nom', 'marque', 'prix', 'categorie', 'forme',
            'couleur', 'image', 'description',
            'stock', 'disponible', 'date_ajout',
            'ajoute_par', 'ajoute_par_nom', 'galerie',
        ]
        read_only_fields = ['id', 'date_ajout', 'ajoute_par', 'ajoute_par_nom']

    def get_ajoute_par_nom(self, obj):
        if obj.ajoute_par:
            return obj.ajoute_par.get_full_name() or obj.ajoute_par.username
        return None
