from rest_framework import serializers
from .models import BoutiqueOpticien


class BoutiqueSerializer(serializers.ModelSerializer):
    opticien_nom = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = BoutiqueOpticien
        fields = [
            'id', 'opticien', 'opticien_nom',
            'nom', 'slogan', 'description',
            'adresse', 'telephone', 'email',
            'logo', 'actif', 'date_creation',
        ]
        read_only_fields = ['id', 'opticien', 'opticien_nom', 'date_creation']

    def get_opticien_nom(self, obj):
        if obj.opticien:
            return obj.opticien.get_full_name() or obj.opticien.username
        return None
