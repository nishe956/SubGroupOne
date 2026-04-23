from rest_framework import serializers
from .models import User

ROLES_PUBLICS = ['client', 'opticien']


class UserSerializer(serializers.ModelSerializer):
    compagnie_assurance_detail = serializers.SerializerMethodField(read_only=True)

    def get_compagnie_assurance_detail(self, obj):
        if obj.compagnie_assurance:
            return {
                'id': obj.compagnie_assurance.id,
                'nom': obj.compagnie_assurance.nom,
                'taux_prise_charge': float(obj.compagnie_assurance.taux_prise_charge),
            }
        return None

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'role', 'telephone', 'adresse', 'date_naissance',
            'compagnie_assurance', 'compagnie_assurance_detail', 'numero_police',
        ]
        read_only_fields = ['id', 'role']


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    role = serializers.ChoiceField(choices=ROLES_PUBLICS, default='client')

    class Meta:
        model = User
        fields = [
            'username', 'email', 'password', 'first_name', 'last_name',
            'role', 'telephone', 'adresse', 'date_naissance',
        ]

    def validate_role(self, value):
        if value not in ROLES_PUBLICS:
            raise serializers.ValidationError("Rôle non autorisé à l'inscription.")
        return value

    def create(self, validated_data):
        return User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            role=validated_data.get('role', 'client'),
            telephone=validated_data.get('telephone', ''),
            adresse=validated_data.get('adresse', ''),
            date_naissance=validated_data.get('date_naissance'),
        )
