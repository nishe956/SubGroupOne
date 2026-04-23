from rest_framework import serializers
from .models import Publication, Commentaire


class CommentaireSerializer(serializers.ModelSerializer):
    auteur_nom = serializers.SerializerMethodField()

    class Meta:
        model  = Commentaire
        fields = ['id', 'auteur', 'auteur_nom', 'contenu', 'date_creation']
        read_only_fields = ['auteur', 'auteur_nom']

    def get_auteur_nom(self, obj):
        return obj.auteur.get_full_name() or obj.auteur.username


class PublicationSerializer(serializers.ModelSerializer):
    auteur_nom         = serializers.SerializerMethodField(read_only=True)
    likes              = serializers.SerializerMethodField(read_only=True)
    commentaires_count = serializers.SerializerMethodField(read_only=True)
    liked              = serializers.SerializerMethodField(read_only=True)
    commentaires       = CommentaireSerializer(many=True, read_only=True)

    class Meta:
        model  = Publication
        fields = [
            'id', 'titre', 'contenu', 'resume', 'categorie', 'image',
            'auteur', 'auteur_nom', 'date_creation', 'publie', 'vues',
            'likes', 'liked', 'commentaires_count', 'commentaires',
        ]
        read_only_fields = ['auteur', 'date_creation', 'vues']

    def get_auteur_nom(self, obj):
        if obj.auteur:
            return obj.auteur.get_full_name() or obj.auteur.username
        return 'OptiLunette'

    def get_likes(self, obj):
        return obj.likes_set.count()

    def get_commentaires_count(self, obj):
        return obj.commentaires.count()

    def get_liked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.likes_set.filter(user=request.user).exists()
        return False
