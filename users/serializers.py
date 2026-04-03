from rest_framework import serializers
from .models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'role', 'telephone', 'adresse']
        read_only_fields = ['id']

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    
    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'role', 'telephone', 'adresse']
    
    def create(self, validated_data):
        # Crée l'utilisateur avec le mot de passe hashé
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            role=validated_data.get('role', 'client'),
            telephone=validated_data.get('telephone', ''),
            adresse=validated_data.get('adresse', ''),
        )
        return user