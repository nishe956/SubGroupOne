from django.urls import reverse
from rest_framework import serializers

from .models import Ordonnance


class OrdonnanceSerializer(serializers.ModelSerializer):
    client_nom = serializers.CharField(source='client.username', read_only=True)
    # L'URL de stockage n'est jamais exposée : le document médical n'est
    # accessible que par la vue authentifiée, qui revérifie les droits.
    image = serializers.ImageField(write_only=True, required=False)
    image_url = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Ordonnance
        fields = [
            'id', 'client', 'client_nom', 'image', 'image_url',
            'oeil_droit_sphere', 'oeil_droit_cylindre', 'oeil_droit_axe',
            'oeil_gauche_sphere', 'oeil_gauche_cylindre', 'oeil_gauche_axe',
            'date_upload', 'validee'
        ]
        # 'validee' ne doit jamais être modifiable par le client : la validation
        # passe exclusivement par ValiderOrdonnance (opticien/admin).
        read_only_fields = ['id', 'date_upload', 'client', 'validee']

    def get_image_url(self, obj):
        if not obj.image:
            return None
        chemin = reverse('image-ordonnance', kwargs={'pk': obj.pk})
        requete = self.context.get('request')
        return requete.build_absolute_uri(chemin) if requete else chemin
