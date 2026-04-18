from rest_framework import permissions

class IsAdminUserRole(permissions.BasePermission):
    """
    Permission permettant l'accès uniquement aux utilisateurs ayant le rôle 'admin'.
    Utilisé pour la gestion des utilisateurs, opticiens et système.
    """
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == 'admin')

class IsOpticianUserRole(permissions.BasePermission):
    """
    Permission permettant l'accès uniquement aux opticiens.
    Utilisé pour la gestion des produits (montures) et commandes clients.
    """
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == 'opticien')

class IsAdminOrOpticianRole(permissions.BasePermission):
    """
    Permission permettant l'accès aux utilisateurs ayant le rôle 'admin' ou 'opticien'.
    """
    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated):
            return False
        return request.user.role in ['admin', 'opticien']
