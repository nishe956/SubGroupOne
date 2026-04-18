from rest_framework import serializers
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Famille, PartnerAssurance, AuditLog

User = get_user_model()

class FamilleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Famille
        fields = ['id', 'nom', 'code_unique', 'nb_membres', 'nb_lunettes_prevues']

class UserSerializer(serializers.ModelSerializer):
    famille_details = FamilleSerializer(source='famille', read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name', 
            'role', 'telephone', 'adresse', 'is_active', 
            'assurance_nom', 'assurance_numero', 'code_famille', 
            'famille', 'famille_details'
        ]

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = User
        fields = ['email', 'password', 'first_name', 'last_name', 'telephone']
        extra_kwargs = {
            'first_name': {'required': False, 'allow_blank': True},
            'last_name': {'required': False, 'allow_blank': True},
            'telephone': {'required': False, 'allow_blank': True},
        }

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Cet email est déjà utilisé.")
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("Ce nom d'utilisateur (email) est déjà utilisé.")
        return value

    def create(self, validated_data):
        # Utiliser l'email comme nom d'utilisateur par défaut
        email = validated_data.get('email')
        validated_data['username'] = email 
        user = User.objects.create_user(**validated_data)
        user.role = 'client'
        user.save()
        return user


from .models import Notification

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'titre', 'message', 'is_read', 'type_notif', 'timestamp', 'related_id']
        read_only_fields = ['id', 'titre', 'message', 'type_notif', 'timestamp', 'related_id']

class PartnerAssuranceSerializer(serializers.ModelSerializer):
    class Meta:
        model = PartnerAssurance
        # Exclude logo to avoid ImageField issues with JSON API
        fields = ['id', 'nom', 'contact', 'taux_couverture_defaut']

class AuditLogSerializer(serializers.ModelSerializer):
    user_email = serializers.SerializerMethodField()
    class Meta:
        model = AuditLog
        fields = ['id', 'user_email', 'action', 'details', 'timestamp']

    def get_user_email(self, obj):
        return obj.user.email if obj.user else 'Système'

class UserAdminSerializer(serializers.ModelSerializer):
    """Serializer étendu pour la gestion administrative des utilisateurs."""
    password = serializers.CharField(write_only=True, required=False, allow_blank=True)

    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'role', 'telephone', 'adresse', 'is_active', 'date_joined', 'password']
        read_only_fields = ['date_joined']
        # username is auto-set from email, not exposed to API

    def create(self, validated_data):
        password = validated_data.pop('password', None) or 'Admin@123'
        email = validated_data['email']
        # Ensure username uniqueness (use email as username)
        if User.objects.filter(email=email).exists():
            raise serializers.ValidationError({'email': 'Un utilisateur avec cet email existe déjà.'})
        validated_data['username'] = email
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.set_password(password)
        instance.save()
        return instance

class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField()
