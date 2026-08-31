from rest_framework import permissions


class CompteUtilisable(permissions.BasePermission):
    """Vérifie à CHAQUE requête que le compte est toujours autorisé à agir.

    Le statut de validation d'un opticien n'était contrôlé qu'au moment du login :
    un opticien rejeté après coup conservait un access token valide, et pouvait le
    renouveler pendant toute la durée de vie du refresh token.
    """

    message = "Votre compte n'est plus autorisé à accéder à cette ressource."

    def has_permission(self, request, view):
        user = request.user
        if not (user and user.is_authenticated):
            return False
        if not user.is_active:
            return False
        if user.role == 'opticien' and user.statut_validation != 'approuve':
            return False
        return True


class IsOpticienOuAdmin(CompteUtilisable):
    """Seuls les opticiens (approuvés) et les admins peuvent accéder."""

    def has_permission(self, request, view):
        return (
            super().has_permission(request, view)
            and request.user.role in ('opticien', 'admin')
        )


class IsAdminSeulement(CompteUtilisable):
    """Réservé aux administrateurs uniquement."""

    def has_permission(self, request, view):
        return super().has_permission(request, view) and request.user.role == 'admin'


class EstProprietaireOuAdmin(permissions.BasePermission):
    """Permission d'objet : l'admin passe partout, l'opticien seulement sur ses
    propres objets.

    `champ_proprietaire` est lu sur la vue, ce qui permet de réutiliser la même
    classe pour des modèles dont le propriétaire ne porte pas le même nom.
    """

    message = "Vous ne pouvez agir que sur vos propres ressources."

    def has_object_permission(self, request, view, obj):
        user = request.user
        if user.role == 'admin':
            return True

        champ = getattr(view, 'champ_proprietaire', 'ajoute_par')
        proprietaire = obj
        for partie in champ.split('__'):
            proprietaire = getattr(proprietaire, partie, None)
            if proprietaire is None:
                # Objet orphelin : seul l'admin y touche.
                return False
        return proprietaire == user
