from rest_framework import serializers
from .models import GroupeFamille


class GroupeFamilleSerializer(serializers.ModelSerializer):
    nb_membres  = serializers.SerializerMethodField()
    taux_rabais = serializers.SerializerMethodField()
    chef_id     = serializers.SerializerMethodField()
    is_chef     = serializers.SerializerMethodField()

    class Meta:
        model  = GroupeFamille
        fields = ['id', 'nom', 'code_invitation', 'date_creation', 'nb_membres', 'taux_rabais', 'chef_id', 'is_chef']

    def get_nb_membres(self, obj):
        return obj.membres.count()

    def get_taux_rabais(self, obj):
        return obj.taux_rabais()

    def get_chef_id(self, obj):
        return obj.chef_id

    def get_is_chef(self, obj):
        request = self.context.get('request')
        if request:
            return obj.chef == request.user
        return False
