from rest_framework import serializers
from .models import Ordonnance

class OrdonnanceSerializer(serializers.ModelSerializer):
    user_email = serializers.SerializerMethodField()

    def get_user_email(self, obj):
        return obj.user.email if obj.user else "Utilisateur Inconnu"

    class Meta:
        model = Ordonnance
        fields = ['id', 'user', 'user_email', 'image', 'texte_extrait', 'date_scan', 'sphere_od', 'cylindre_od', 'axe_od', 'sphere_og', 'cylindre_og', 'axe_og', 'addition']
        read_only_fields = ['user', 'texte_extrait', 'date_scan']
