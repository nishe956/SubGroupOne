from rest_framework import permissions


class IsOpticienOuAdmin(permissions.BasePermission):
    """Seuls les opticiens et admins peuvent accéder."""
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role in ['opticien', 'admin']
        )


class IsAdminSeulement(permissions.BasePermission):
    """Réservé aux administrateurs uniquement."""
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role == 'admin'
        )
