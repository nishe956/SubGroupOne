from django.contrib import admin
from .models import Ordonnance

@admin.register(Ordonnance)
class OrdonnanceAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'date_scan']
    search_fields = ['user__username']
