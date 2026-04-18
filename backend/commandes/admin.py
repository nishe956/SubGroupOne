from django.contrib import admin
from .models import Commande

@admin.register(Commande)
class CommandeAdmin(admin.ModelAdmin):
    list_display = [
        'id', 'user', 'monture', 'quantite', 'prix_total', 
        'part_client', 'part_assurance', 'remise_famille', 
        'type_livraison', 'mode_paiement', 'statut', 'date_commande'
    ]
    list_filter = ['statut', 'type_livraison', 'mode_paiement']
    search_fields = ['user__email', 'user__username', 'monture__nom']
