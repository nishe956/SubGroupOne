from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, Famille

@admin.register(Famille)
class FamilleAdmin(admin.ModelAdmin):
    list_display = ['id', 'nom', 'code_unique', 'chef_famille', 'nb_membres', 'nb_lunettes_prevues']
    search_fields = ['nom', 'code_unique']

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    fieldsets = UserAdmin.fieldsets + (
        ('Informations supplémentaires', {'fields': ('role', 'telephone', 'adresse', 'assurance_nom', 'assurance_numero', 'famille', 'code_famille')}),
    )
    list_display = ['username', 'email', 'role', 'famille', 'is_active']
    list_filter = ['role', 'is_active', 'famille']
