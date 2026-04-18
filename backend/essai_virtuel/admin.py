from django.contrib import admin
from .models import EssaiVirtuel

@admin.register(EssaiVirtuel)
class EssaiVirtuelAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'monture', 'date_essai']
    search_fields = ['user__username', 'monture__nom']
