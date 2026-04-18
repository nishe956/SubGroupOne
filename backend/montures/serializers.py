from rest_framework import serializers
from .models import Monture

class MontureSerializer(serializers.ModelSerializer):
    class Meta:
        model = Monture
        fields = '__all__'
