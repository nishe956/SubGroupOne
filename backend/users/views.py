import os
import hashlib
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.token_blacklist.models import OutstandingToken, BlacklistedToken
from django.conf import settings
from django.contrib.auth import authenticate
from django.contrib.auth.tokens import default_token_generator
from django.core.cache import cache
from django.core.exceptions import ValidationError as DjangoValidationError
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_decode, urlsafe_base64_encode
from .models import User
from .serializers import UserSerializer, RegisterSerializer
from .permissions import IsOpticienOuAdmin, IsAdminSeulement
from .emails import envoyer_email_reset_password
from django.contrib.auth.password_validation import validate_password


def _emettre_tokens(user):
    """Génère les tokens JWT et la réponse (access/refresh + cookie httpOnly), utilisé
    par tous les points d'entrée d'authentification (login classique, Google...)."""
    refresh = RefreshToken.for_user(user)
    access_token  = str(refresh.access_token)
    refresh_token = str(refresh)

    response = Response({
        'access': access_token,
        'refresh': refresh_token,
        'user': UserSerializer(user).data,
    })

    # Stocker le refresh token dans un cookie httpOnly (inaccessible au JS)
    is_prod = os.getenv('DJANGO_ENV', 'development') == 'production'
    response.set_cookie(
        'refresh_token',
        refresh_token,
        httponly=True,
        secure=is_prod,
        samesite='Lax',
        max_age=7 * 24 * 3600,
        path='/api/users/token/refresh/',
    )
    return response


class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        from boutique.models import BoutiqueOpticien
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            if user.role == 'opticien':
                # Compte opticien créé mais soumis à validation par un administrateur.
                user.statut_validation = 'en_attente'
                user.save(update_fields=['statut_validation'])
                BoutiqueOpticien.objects.create(
                    opticien=user,
                    nom=request.data.get('boutique_nom', f"Boutique {user.username}"),
                    adresse=request.data.get('boutique_adresse', ''),
                    telephone=request.data.get('boutique_telephone', user.telephone),
                    description=request.data.get('boutique_description', ''),
                    slogan=request.data.get('boutique_slogan', ''),
                )
            return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        username = request.data.get('username') or request.data.get('email')
        password = request.data.get('password')

        # Rate limiting : max 5 tentatives par 10 minutes, par IP ET par identifiant.
        # X-Forwarded-For est contrôlé par le client : on ne s'y fie que derrière un
        # proxy de confiance (TRUST_PROXY), sinon on utilise REMOTE_ADDR (non falsifiable).
        if os.getenv('TRUST_PROXY', 'False').lower() in ('true', '1'):
            ip = request.META.get('HTTP_X_FORWARDED_FOR', request.META.get('REMOTE_ADDR', '')).split(',')[0].strip()
        else:
            ip = request.META.get('REMOTE_ADDR', '')
        empreinte = hashlib.sha256(f'{ip}_{(username or "").lower()}'.encode()).hexdigest()
        cache_key = f'login_attempts_{empreinte}'
        attempts = cache.get(cache_key, 0)
        if attempts >= 5:
            return Response(
                {'detail': 'Trop de tentatives de connexion. Réessayez dans 10 minutes.'},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        # Allow login with email
        if username and '@' in username:
            try:
                user_obj = User.objects.get(email=username)
                username = user_obj.username
            except User.DoesNotExist:
                pass

        user = authenticate(username=username, password=password)

        if user:
            # Un opticien doit être validé par un administrateur avant de pouvoir se connecter.
            if user.role == 'opticien' and user.statut_validation != 'approuve':
                cache.delete(cache_key)
                if user.statut_validation == 'rejete':
                    msg = "Votre demande de compte opticien a été refusée. Contactez l'administrateur."
                else:
                    msg = "Votre compte opticien est en attente de validation par un administrateur."
                return Response({'detail': msg}, status=status.HTTP_403_FORBIDDEN)

            cache.delete(cache_key)
            return _emettre_tokens(user)

        cache.set(cache_key, attempts + 1, timeout=600)
        return Response({'detail': 'Email ou mot de passe incorrect.'}, status=status.HTTP_400_BAD_REQUEST)


class ProfilView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


class ChangePasswordView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        user = request.user
        ancien = request.data.get('ancien_mot_de_passe') or request.data.get('old_password')
        nouveau = request.data.get('nouveau_mot_de_passe') or request.data.get('new_password')

        if not user.check_password(ancien):
            return Response({'detail': 'Ancien mot de passe incorrect.'}, status=status.HTTP_400_BAD_REQUEST)

        if not nouveau or len(nouveau) < 8:
            return Response({'detail': 'Le nouveau mot de passe doit avoir au moins 8 caractères.'}, status=status.HTTP_400_BAD_REQUEST)
        
        validate_password(nouveau, user=user)
        user.set_password(nouveau)
        user.save()
        return Response({'detail': 'Mot de passe changé avec succès.'})


class LogoutView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        # Révoque le refresh token pour empêcher toute réémission d'access token.
        token_str = request.data.get('refresh') or request.COOKIES.get('refresh_token')
        if token_str:
            try:
                RefreshToken(token_str).blacklist()
            except Exception:
                pass  # token déjà expiré / invalide : la déconnexion reste effective
        response = Response({'detail': 'Déconnexion réussie.'})
        response.delete_cookie('refresh_token', path='/api/users/token/refresh/')
        return response


class PasswordResetRequestView(APIView):
    """Demande de réinitialisation : envoie un email si le compte existe.

    Répond toujours avec le même message générique, que l'email soit connu ou non,
    pour ne jamais révéler si une adresse est associée à un compte.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = (request.data.get('email') or '').strip()

        # Rate limiting : même principe que LoginView, par IP ET par email.
        if os.getenv('TRUST_PROXY', 'False').lower() in ('true', '1'):
            ip = request.META.get('HTTP_X_FORWARDED_FOR', request.META.get('REMOTE_ADDR', '')).split(',')[0].strip()
        else:
            ip = request.META.get('REMOTE_ADDR', '')
        empreinte = hashlib.sha256(f'{ip}_{email.lower()}'.encode()).hexdigest()
        cache_key = f'password_reset_attempts_{empreinte}'
        attempts = cache.get(cache_key, 0)
        if attempts >= 5:
            return Response(
                {'detail': 'Trop de demandes. Réessayez dans 10 minutes.'},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        cache.set(cache_key, attempts + 1, timeout=600)

        reponse_generique = Response({
            'detail': "Si un compte existe avec cet email, un lien de réinitialisation vient d'être envoyé."
        })

        if not email:
            return reponse_generique

        user = User.objects.filter(email=email).first()
        if user is not None:
            uid = urlsafe_base64_encode(force_bytes(user.pk))
            token = default_token_generator.make_token(user)
            lien = f"{settings.FRONTEND_URL}/reinitialiser-mot-de-passe?uid={uid}&token={token}"
            envoyer_email_reset_password(user, lien)

        return reponse_generique


class PasswordResetConfirmView(APIView):
    """Confirme la réinitialisation à partir du lien reçu par email."""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        uid = request.data.get('uid')
        token = request.data.get('token')
        nouveau = request.data.get('new_password') or request.data.get('nouveau_mot_de_passe')

        try:
            user_pk = force_str(urlsafe_base64_decode(uid))
            user = User.objects.get(pk=user_pk)
        except (TypeError, ValueError, OverflowError, User.DoesNotExist):
            return Response({'detail': 'Lien de réinitialisation invalide.'}, status=status.HTTP_400_BAD_REQUEST)

        if not default_token_generator.check_token(user, token):
            return Response({'detail': 'Lien de réinitialisation invalide ou expiré.'}, status=status.HTTP_400_BAD_REQUEST)

        if not nouveau or len(nouveau) < 8:
            return Response({'detail': 'Le nouveau mot de passe doit avoir au moins 8 caractères.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            validate_password(nouveau, user=user)
        except DjangoValidationError as exc:
            return Response({'detail': ' '.join(exc.messages)}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(nouveau)
        user.save()

        # Invalide toutes les sessions existantes : un reset de mot de passe doit
        # déconnecter les autres appareils éventuellement compromis.
        for outstanding in OutstandingToken.objects.filter(user=user):
            BlacklistedToken.objects.get_or_create(token=outstanding)

        return Response({'detail': 'Mot de passe réinitialisé avec succès.'})


class GoogleLoginView(APIView):
    """Connexion/inscription via Google Identity Services.

    Le frontend envoie le jeton d'identité (`credential`) obtenu après le popup Google ;
    on le vérifie auprès de Google puis on retrouve ou crée le compte correspondant.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        credential = request.data.get('credential')
        if not credential:
            return Response({'detail': 'Jeton Google manquant.'}, status=status.HTTP_400_BAD_REQUEST)

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
        user = User.objects.filter(email=email).first()

        if user is None:
            base_username = email.split('@')[0] or 'utilisateur'
            username = base_username
            suffix = 1
            while User.objects.filter(username=username).exists():
                suffix += 1
                username = f"{base_username}{suffix}"

            # password=None => Django crée un mot de passe "unusable" : ce compte ne
            # peut se connecter que via Google tant qu'aucun mot de passe n'est défini.
            user = User.objects.create_user(
                username=username,
                email=email,
                password=None,
                first_name=payload.get('given_name', ''),
                last_name=payload.get('family_name', ''),
                role='client',
            )
        elif user.role == 'opticien' and user.statut_validation != 'approuve':
            if user.statut_validation == 'rejete':
                msg = "Votre demande de compte opticien a été refusée. Contactez l'administrateur."
            else:
                msg = "Votre compte opticien est en attente de validation par un administrateur."
            return Response({'detail': msg}, status=status.HTTP_403_FORBIDDEN)

        return _emettre_tokens(user)


class ListeUtilisateursView(generics.ListAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAdminSeulement]


class UpdateDeleteUtilisateurView(generics.RetrieveUpdateDestroyAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAdminSeulement]


class CreerOpticienView(APIView):
    """Admin crée un compte opticien."""
    permission_classes = [IsAdminSeulement]

    def post(self, request):
        data = request.data.copy()
        data['role'] = 'opticien'
        serializer = RegisterSerializer(data=data)
        if serializer.is_valid():
            user = serializer.save()
            return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ListeOpticiens(generics.ListAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsOpticienOuAdmin]

    def get_queryset(self):
        return User.objects.filter(role='opticien')


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
            return Response({'detail': 'Opticien approuvé.', 'statut_validation': 'approuve'})
        if action == 'rejeter':
            opticien.statut_validation = 'rejete'
            opticien.save(update_fields=['statut_validation'])
            # Masque immédiatement sa boutique du catalogue public.
            from boutique.models import BoutiqueOpticien
            BoutiqueOpticien.objects.filter(opticien=opticien).update(actif=False)
            return Response({'detail': 'Demande rejetée.', 'statut_validation': 'rejete'})

        return Response(
            {'detail': "Action invalide. Utilisez 'approuver' ou 'rejeter'."},
            status=status.HTTP_400_BAD_REQUEST,
        )
