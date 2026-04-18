from rest_framework import serializers
from .models import EssaiVirtuel

class EssaiVirtuelSerializer(serializers.ModelSerializer):
    class Meta:
        model = EssaiVirtuel
        fields = '__all__'
        read_only_fields = ['user', 'image_resultat', 'date_essai']
