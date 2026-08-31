import hashlib

from django.conf import settings
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth.tokens import default_token_generator
from django.core.cache import cache
from django.core.exceptions import ValidationError as DjangoValidationError
from django.utils import timezone
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_decode, urlsafe_base64_encode
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from rest_framework_simplejwt.token_blacklist.models import BlacklistedToken, OutstandingToken
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView

from utils.audit import journaliser
from utils.reseau import adresse_client as _adresse_client
from utils.throttles import (
    ThrottleConnexion, ThrottleInscription, ThrottleReset,
)

from .emails import envoyer_email_demande_opticien, envoyer_email_reset_password
from .models import User
from .permissions import CompteUtilisable, IsAdminSeulement, IsOpticienOuAdmin
from .serializers import RegisterSerializer, UserSerializer


def _poser_cookie_refresh(response, refresh_token):
    """Dépose le refresh token dans un cookie httpOnly.

    C'est le SEUL endroit où il transite : il n'est plus renvoyé dans le corps
    de la réponse, pour qu'aucune XSS ne puisse le lire depuis JavaScript.
    """
    response.set_cookie(
        settings.REFRESH_COOKIE_NAME,
        refresh_token,
        httponly=True,
        secure=settings.REFRESH_COOKIE_SECURE,
        samesite=settings.REFRESH_COOKIE_SAMESITE,
        max_age=int(settings.SIMPLE_JWT['REFRESH_TOKEN_LIFETIME'].total_seconds()),
        path=settings.REFRESH_COOKIE_PATH,
    )
    return response


def _emettre_tokens(user):
    """Génère les jetons JWT et la réponse, pour tous les points d'entrée
    d'authentification (login classique, Google...)."""
    refresh = RefreshToken.for_user(user)

    response = Response({
        'access': str(refresh.access_token),
        'user': UserSerializer(user).data,
    })
    return _poser_cookie_refresh(response, str(refresh))


def _revoquer_sessions(user, motif):
    """Invalide tous les jetons existants de l'utilisateur.

    Les refresh tokens sont blacklistés ET la date de révocation est avancée,
    ce qui neutralise aussi les access tokens déjà émis (voir
    users.authentication.JWTAuthentificationRevocable).
    """
    for outstanding in OutstandingToken.objects.filter(user=user):
        BlacklistedToken.objects.get_or_create(token=outstanding)
    user.tokens_valides_apres = timezone.now()
    user.save(update_fields=['tokens_valides_apres'])
    journaliser('revocation_sessions', user, cible_id=user.pk, motif=motif)


class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]
    throttle_classes = [ThrottleInscription]

    def post(self, request):
        from boutique.models import BoutiqueOpticien

        serializer = RegisterSerializer(data=request.data)
        if not serializer.is_valid():
            # Réponse volontairement uniforme sur les champs d'identité : le
            # détail « un utilisateur avec ce nom existe déjà » permettait
            # d'énumérer les comptes avant une attaque par credential stuffing.
            erreurs = dict(serializer.errors)
            for champ in ('username', 'email'):
                if champ in erreurs:
                    erreurs[champ] = [
                        "Cette valeur n'est pas utilisable. Choisissez-en une autre."
                    ]
            return Response(erreurs, status=status.HTTP_400_BAD_REQUEST)

        user = serializer.save()
        if user.role == 'opticien':
            # Compte opticien créé mais soumis à validation par un administrateur.
            # La boutique est créée inactive : elle ne doit pas apparaître au
            # catalogue public avant la décision.
            user.statut_validation = 'en_attente'
            user.save(update_fields=['statut_validation'])
            boutique = BoutiqueOpticien.objects.create(
                opticien=user,
                nom=request.data.get('boutique_nom', f"Boutique {user.username}")[:200],
                adresse=request.data.get('boutique_adresse', ''),
                telephone=request.data.get('boutique_telephone', user.telephone)[:20],
                description=request.data.get('boutique_description', ''),
                slogan=request.data.get('boutique_slogan', '')[:300],
                actif=False,
            )
            # Prévient les administrateurs : sans notification, une demande
            # pouvait rester en attente indéfiniment.
            envoyer_email_demande_opticien(user, boutique)
        journaliser('inscription', user, role=user.role)
        return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)


class LoginView(APIView):
    permission_classes = [permissions.AllowAny]
    # ThrottleConnexion limite par IP seule : sans cela, le « password spraying »
    # (un mot de passe courant essayé sur des milliers de comptes différents
    # depuis une même IP) n'était couvert par aucun compteur.
    throttle_classes = [ThrottleConnexion]

    TENTATIVES_MAX = 5
    FENETRE = 600  # secondes

    def post(self, request):
        username = request.data.get('username') or request.data.get('email')
        password = request.data.get('password')

        if not username or not password:
            return Response(
                {'detail': 'Email ou mot de passe incorrect.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Second compteur, par couple (IP, identifiant), contre le bruteforce ciblé.
        ip = _adresse_client(request)
        empreinte = hashlib.sha256(f'{ip}_{username.lower()}'.encode()).hexdigest()
        cache_key = f'login_attempts_{empreinte}'

        if cache.get(cache_key, 0) >= self.TENTATIVES_MAX:
            return Response(
                {'detail': 'Trop de tentatives de connexion. Réessayez dans 10 minutes.'},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        # Connexion possible par email
        if '@' in username:
            user_obj = User.objects.filter(email__iexact=username).first()
            if user_obj is not None:
                username = user_obj.username

        user = authenticate(username=username, password=password)

        if user is None:
            self._incrementer(cache_key)
            journaliser('connexion_echouee', None, ip=ip)
            return Response(
                {'detail': 'Email ou mot de passe incorrect.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Un opticien doit être validé par un administrateur avant de se connecter.
        if user.role == 'opticien' and user.statut_validation != 'approuve':
            cache.delete(cache_key)
            if user.statut_validation == 'rejete':
                msg = "Votre demande de compte opticien a été refusée. Contactez l'administrateur."
            else:
                msg = "Votre compte opticien est en attente de validation par un administrateur."
            return Response({'detail': msg}, status=status.HTTP_403_FORBIDDEN)

        cache.delete(cache_key)
        journaliser('connexion', user, ip=ip)
        return _emettre_tokens(user)

    def _incrementer(self, cache_key):
        """Incrément atomique : `get` puis `set` laissait des requêtes
        concurrentes lire et réécrire la même valeur."""
        try:
            cache.incr(cache_key)
        except ValueError:
            cache.set(cache_key, 1, timeout=self.FENETRE)


class RafraichirTokenView(TokenRefreshView):
    """Renouvelle l'access token à partir du cookie httpOnly.

    Le refresh token n'est plus accepté depuis le corps de la requête : il ne doit
    jamais être manipulable par du JavaScript. La rotation étant active, le
    nouveau refresh token est immédiatement redéposé dans le cookie.
    """
    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    def post(self, request, *args, **kwargs):
        token = request.COOKIES.get(settings.REFRESH_COOKIE_NAME)
        if not token:
            return Response(
                {'detail': 'Session expirée, veuillez vous reconnecter.'},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        serializer = self.get_serializer(data={'refresh': token})
        try:
            serializer.is_valid(raise_exception=True)
        except (TokenError, InvalidToken):
            reponse = Response(
                {'detail': 'Session expirée, veuillez vous reconnecter.'},
                status=status.HTTP_401_UNAUTHORIZED,
            )
            reponse.delete_cookie(
                settings.REFRESH_COOKIE_NAME, path=settings.REFRESH_COOKIE_PATH
            )
            return reponse

        donnees = dict(serializer.validated_data)
        nouveau_refresh = donnees.pop('refresh', None)
        reponse = Response(donnees)
        if nouveau_refresh:
            _poser_cookie_refresh(reponse, nouveau_refresh)
        return reponse


class ProfilView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [CompteUtilisable]

    def get_object(self):
        return self.request.user


class ChangePasswordView(APIView):
    permission_classes = [CompteUtilisable]

    def post(self, request):
        user = request.user
        ancien = request.data.get('ancien_mot_de_passe') or request.data.get('old_password')
        nouveau = request.data.get('nouveau_mot_de_passe') or request.data.get('new_password')

        if not ancien or not user.check_password(ancien):
            return Response(
                {'detail': 'Ancien mot de passe incorrect.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not nouveau:
            return Response(
                {'detail': 'Le nouveau mot de passe est obligatoire.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            validate_password(nouveau, user=user)
        except DjangoValidationError as exc:
            return Response({'detail': ' '.join(exc.messages)}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(nouveau)
        user.save()
        # Un changement de mot de passe doit déconnecter tous les autres
        # appareils, y compris ceux qui détiennent un access token encore valide.
        _revoquer_sessions(user, motif='changement_mot_de_passe')

        reponse = Response({
            'detail': 'Mot de passe changé avec succès. Veuillez vous reconnecter.'
        })
        reponse.delete_cookie(settings.REFRESH_COOKIE_NAME, path=settings.REFRESH_COOKIE_PATH)
        return reponse


class LogoutView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        token_str = request.COOKIES.get(settings.REFRESH_COOKIE_NAME)
        if token_str:
            try:
                RefreshToken(token_str).blacklist()
            except TokenError:
                pass  # token déjà expiré / invalide : la déconnexion reste effective

        journaliser('deconnexion', request.user)
        response = Response({'detail': 'Déconnexion réussie.'})
        response.delete_cookie(settings.REFRESH_COOKIE_NAME, path=settings.REFRESH_COOKIE_PATH)
        return response


class PasswordResetRequestView(APIView):
    """Demande de réinitialisation : envoie un email si le compte existe.

    Répond toujours avec le même message générique, que l'email soit connu ou non,
    pour ne jamais révéler si une adresse est associée à un compte.
    """
    permission_classes = [permissions.AllowAny]
    throttle_classes = [ThrottleReset]

    def post(self, request):
        email = (request.data.get('email') or '').strip()

        # Compteur secondaire par couple (IP, email), en plus du quota par IP.
        ip = _adresse_client(request)
        empreinte = hashlib.sha256(f'{ip}_{email.lower()}'.encode()).hexdigest()
        cache_key = f'password_reset_attempts_{empreinte}'
        if cache.get(cache_key, 0) >= 5:
            return Response(
                {'detail': 'Trop de demandes. Réessayez dans 10 minutes.'},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        try:
            cache.incr(cache_key)
        except ValueError:
            cache.set(cache_key, 1, timeout=600)

        reponse_generique = Response({
            'detail': "Si un compte existe avec cet email, un lien de réinitialisation vient d'être envoyé."
        })

        if not email:
            return reponse_generique

        user = User.objects.filter(email__iexact=email, is_active=True).first()
        if user is not None:
            uid = urlsafe_base64_encode(force_bytes(user.pk))
            token = default_token_generator.make_token(user)
            lien = f"{settings.FRONTEND_URL}/reinitialiser-mot-de-passe?uid={uid}&token={token}"
            envoyer_email_reset_password(user, lien)
            journaliser('demande_reset_mot_de_passe', user, ip=ip)

        return reponse_generique


class PasswordResetConfirmView(APIView):
    """Confirme la réinitialisation à partir du lien reçu par email."""
    permission_classes = [permissions.AllowAny]
    throttle_classes = [ThrottleReset]

    def post(self, request):
        uid = request.data.get('uid')
        token = request.data.get('token')
        nouveau = request.data.get('new_password') or request.data.get('nouveau_mot_de_passe')

        try:
            user_pk = force_str(urlsafe_base64_decode(uid))
            user = User.objects.get(pk=user_pk)
        except (TypeError, ValueError, OverflowError, User.DoesNotExist):
            return Response(
                {'detail': 'Lien de réinitialisation invalide.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not default_token_generator.check_token(user, token):
            return Response(
                {'detail': 'Lien de réinitialisation invalide ou expiré.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not nouveau:
            return Response(
                {'detail': 'Le nouveau mot de passe est obligatoire.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            validate_password(nouveau, user=user)
        except DjangoValidationError as exc:
            return Response({'detail': ' '.join(exc.messages)}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(nouveau)
        user.save()
        _revoquer_sessions(user, motif='reinitialisation_mot_de_passe')

        return Response({'detail': 'Mot de passe réinitialisé avec succès.'})


class GoogleLoginView(APIView):
    """Connexion/inscription via Google Identity Services.

    Le frontend envoie le jeton d'identité (`credential`) obtenu après le popup
    Google ; on le vérifie auprès de Google puis on retrouve ou crée le compte.
    """
    permission_classes = [permissions.AllowAny]
    throttle_classes = [ThrottleConnexion]

    def post(self, request):
        credential = request.data.get('credential')
        if not credential:
            return Response({'detail': 'Jeton Google manquant.'}, status=status.HTTP_400_BAD_REQUEST)

        if not settings.GOOGLE_CLIENT_ID:
            return Response(
                {'detail': "La connexion Google n'est pas configurée."},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        from google.auth.transport import requests as google_requests
        from google.oauth2 import id_token as google_id_token

        try:
            payload = google_id_token.verify_oauth2_token(
                credential, google_requests.Request(), settings.GOOGLE_CLIENT_ID,
            )
        except ValueError:
            return Response({'detail': 'Jeton Google invalide.'}, status=status.HTTP_400_BAD_REQUEST)

        if not payload.get('email_verified'):
            return Response({'detail': 'Email Google non vérifié.'}, status=status.HTTP_400_BAD_REQUEST)

        email = payload['email']
        user = User.objects.filter(email__iexact=email).first()

        if user is None:
            base_username = email.split('@')[0] or 'utilisateur'
            username = base_username
            suffix = 1
            while User.objects.filter(username=username).exists():
                suffix += 1
                username = f"{base_username}{suffix}"

            # password=None => Django crée un mot de passe "unusable" : ce compte
            # ne peut se connecter que via Google tant qu'aucun mot de passe n'est défini.
            user = User.objects.create_user(
                username=username,
                email=email,
                password=None,
                first_name=payload.get('given_name', ''),
                last_name=payload.get('family_name', ''),
                role='client',
            )
            journaliser('inscription_google', user)
        else:
            if not user.is_active:
                return Response(
                    {'detail': 'Ce compte est désactivé.'}, status=status.HTTP_403_FORBIDDEN
                )
            if user.role == 'opticien' and user.statut_validation != 'approuve':
                if user.statut_validation == 'rejete':
                    msg = "Votre demande de compte opticien a été refusée. Contactez l'administrateur."
                else:
                    msg = "Votre compte opticien est en attente de validation par un administrateur."
                return Response({'detail': msg}, status=status.HTTP_403_FORBIDDEN)

        journaliser('connexion_google', user)
        return _emettre_tokens(user)


class ListeUtilisateursView(generics.ListAPIView):
    """Comptes actifs de la plateforme.

    Les demandes d'opticien en attente en sont exclues : tant qu'aucune décision
    n'a été prise, elles n'ont pas leur place parmi les comptes validés. Elles
    sont traitées dans l'écran dédié (OpticiensEnAttenteView). `?en_attente=true`
    permet malgré tout de les consulter explicitement.
    """
    serializer_class = UserSerializer
    permission_classes = [IsAdminSeulement]

    def get_queryset(self):
        qs = User.objects.all().order_by('-date_joined')
        if self.request.query_params.get('en_attente') == 'true':
            return qs.filter(role='opticien', statut_validation='en_attente')
        return qs.exclude(role='opticien', statut_validation='en_attente')


class UpdateDeleteUtilisateurView(generics.RetrieveUpdateDestroyAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAdminSeulement]

    def perform_destroy(self, instance):
        journaliser('suppression_utilisateur', self.request.user,
                    cible_id=instance.pk, cible_role=instance.role)
        super().perform_destroy(instance)


class CreerOpticienView(APIView):
    """Admin crée un compte opticien."""
    permission_classes = [IsAdminSeulement]

    def post(self, request):
        data = request.data.copy()
        data['role'] = 'opticien'
        serializer = RegisterSerializer(data=data)
        if serializer.is_valid():
            user = serializer.save()
            journaliser('creation_opticien', request.user, cible_id=user.pk)
            return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ListeOpticiens(generics.ListAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsOpticienOuAdmin]

    def get_queryset(self):
        return User.objects.filter(role='opticien', statut_validation='approuve').order_by('username')


class ListeClients(generics.ListAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsAdminSeulement]

    def get_queryset(self):
        return User.objects.filter(role='client').order_by('-date_joined')


class OpticiensEnAttenteView(generics.ListAPIView):
    """Demandes d'inscription opticien en attente de validation."""
    serializer_class = UserSerializer
    permission_classes = [IsAdminSeulement]

    def get_queryset(self):
        return User.objects.filter(
            role='opticien', statut_validation='en_attente'
        ).order_by('-date_joined')


class ValiderOpticienView(APIView):
    """L'admin approuve ou rejette une demande de compte opticien."""
    permission_classes = [IsAdminSeulement]

    def post(self, request, pk):
        try:
            opticien = User.objects.get(pk=pk, role='opticien')
        except User.DoesNotExist:
            return Response({'detail': 'Opticien introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        action = request.data.get('action')
        if action == 'approuver':
            opticien.statut_validation = 'approuve'
            opticien.save(update_fields=['statut_validation'])
            # La boutique est créée inactive à l'inscription : l'approbation est
            # ce qui la rend visible au catalogue public.
            from boutique.models import BoutiqueOpticien
            BoutiqueOpticien.objects.filter(opticien=opticien).update(actif=True)
            journaliser('validation_opticien', request.user, cible_id=opticien.pk, decision='approuve')
            return Response({'detail': 'Opticien approuvé.', 'statut_validation': 'approuve'})

        if action == 'rejeter':
            opticien.statut_validation = 'rejete'
            opticien.save(update_fields=['statut_validation'])
            # Masque immédiatement sa boutique du catalogue public...
            from boutique.models import BoutiqueOpticien
            BoutiqueOpticien.objects.filter(opticien=opticien).update(actif=False)
            # ...et coupe ses sessions en cours : le statut n'était vérifié qu'au
            # login, un opticien rejeté gardait sinon son accès plusieurs jours.
            _revoquer_sessions(opticien, motif='rejet_compte_opticien')
            journaliser('validation_opticien', request.user, cible_id=opticien.pk, decision='rejete')
            return Response({'detail': 'Demande rejetée.', 'statut_validation': 'rejete'})

        return Response(
            {'detail': "Action invalide. Utilisez 'approuver' ou 'rejeter'."},
            status=status.HTTP_400_BAD_REQUEST,
        )
