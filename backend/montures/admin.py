from django.contrib import admin
from .models import Monture

@admin.register(Monture)
class MontureAdmin(admin.ModelAdmin):
    list_display = ['nom', 'marque', 'prix', 'forme', 'genre', 'stock', 'disponible']
    list_filter = ['forme', 'genre', 'disponible']
    search_fields = ['nom', 'marque']
