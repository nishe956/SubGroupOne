from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
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
            'statut_validation', 'date_joined',
        ]
        # `role` et `statut_validation` doivent rester non modifiables : ce sont
        # les deux champs qui permettraient une élévation de privilège via
        # PATCH /api/users/profil/.
        read_only_fields = ['id', 'role', 'statut_validation', 'date_joined']


class UserPublicSerializer(serializers.ModelSerializer):
    """Vue restreinte d'un utilisateur, pour les contextes où l'appelant n'a pas
    à connaître les coordonnées complètes (membres d'un groupe famille,
    listes d'opticiens...)."""

    nom_affiche = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = User
        fields = ['id', 'nom_affiche', 'role']

    def get_nom_affiche(self, obj):
        return obj.get_full_name() or obj.username


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    role = serializers.ChoiceField(choices=ROLES_PUBLICS, default='client')

    class Meta:
        model = User
        fields = [
            'username', 'email', 'password', 'first_name', 'last_name',
            'role', 'telephone', 'adresse', 'date_naissance',
        ]
        extra_kwargs = {'email': {'required': True, 'allow_blank': False}}

    def validate_role(self, value):
        if value not in ROLES_PUBLICS:
            raise serializers.ValidationError("Rôle non autorisé à l'inscription.")
        return value

    def validate_password(self, value):
        # Applique les mêmes règles que le changement et la réinitialisation de
        # mot de passe (longueur, similarité, mots de passe courants).
        try:
            validate_password(value)
        except DjangoValidationError as exc:
            raise serializers.ValidationError(list(exc.messages))
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
