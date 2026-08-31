"""Authentification JWT avec révocation immédiate.

`simplejwt` sait blacklister un refresh token, mais rien n'invalide un access
token déjà émis : après un changement de mot de passe, un rejet de compte ou une
désactivation, la session compromise restait utilisable jusqu'à l'expiration
naturelle du jeton.

On compare donc le `iat` du jeton au champ `tokens_valides_apres` de
l'utilisateur, mis à jour lors de ces événements.
"""
from datetime import datetime, timezone

from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import AuthenticationFailed


class JWTAuthentificationRevocable(JWTAuthentication):

    def get_user(self, validated_token):
        user = super().get_user(validated_token)

        limite = getattr(user, 'tokens_valides_apres', None)
        if limite is None:
            return user

        emis_le = validated_token.get('iat')
        if emis_le is None:
            # Jeton sans `iat` : impossible de prouver qu'il est postérieur à la
            # révocation, on refuse plutôt que de supposer.
            raise AuthenticationFailed(
                "Session expirée, veuillez vous reconnecter.", code='token_revoque'
            )

        if datetime.fromtimestamp(emis_le, tz=timezone.utc) < limite:
            raise AuthenticationFailed(
                "Session expirée, veuillez vous reconnecter.", code='token_revoque'
            )

        return user
