from rest_framework import serializers
from .models import HistoriqueSMS, CampagneMarketing


class HistoriqueSMSSerializer(serializers.ModelSerializer):
    destinataire_nom = serializers.SerializerMethodField()

    class Meta:
        model  = HistoriqueSMS
        fields = ['id', 'destinataire', 'destinataire_nom', 'telephone', 'message', 'type_message', 'envoye', 'date_envoi']

    def get_destinataire_nom(self, obj):
        if obj.destinataire:
            return obj.destinataire.get_full_name() or obj.destinataire.username
        return obj.telephone


class CampagneSerializer(serializers.ModelSerializer):
    class Meta:
        model  = CampagneMarketing
        fields = ['id', 'nom', 'description', 'message', 'statut', 'cible', 'date_debut', 'date_fin', 'nb_envoyes', 'date_creation']
        read_only_fields = ['nb_envoyes', 'date_creation']
