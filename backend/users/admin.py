from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User

class CustomUserAdmin(UserAdmin):
    fieldsets = UserAdmin.fieldsets + (
        ('Informations supplémentaires', {
            'fields': ('role', 'telephone', 'adresse')
        }),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Informations supplémentaires', {
            'fields': ('role', 'telephone', 'adresse')
        }),
    )
    list_display = ['username', 'email', 'role', 'statut_validation', 'is_staff']
    list_filter = ['role', 'statut_validation', 'is_staff']
    # `role` n'est volontairement PAS dans list_editable : un champ de privilège
    # modifiable en un clic depuis la liste transforme un compte staff compromis
    # en compte administrateur. Le changement passe par la fiche de détail.
    readonly_fields = ['tokens_valides_apres']

admin.site.register(User, CustomUserAdmin)