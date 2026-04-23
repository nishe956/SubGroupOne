from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.core.cache import cache
from .models import User
from .serializers import UserSerializer, RegisterSerializer
from .permissions import IsOpticienOuAdmin


class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        from boutique.models import BoutiqueOpticien
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            if user.role == 'opticien':
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

        # Rate limiting : max 5 tentatives par IP par 10 minutes
        ip = request.META.get('HTTP_X_FORWARDED_FOR', request.META.get('REMOTE_ADDR', '')).split(',')[0].strip()
        cache_key = f'login_attempts_{ip}'
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
            cache.delete(cache_key)
            refresh = RefreshToken.for_user(user)
            access_token  = str(refresh.access_token)
            refresh_token = str(refresh)

            response = Response({
                'access': access_token,
                'refresh': refresh_token,
                'user': UserSerializer(user).data,
            })

            # Stocker le refresh token dans un cookie httpOnly (inaccessible au JS)
            import os
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

        user.set_password(nouveau)
        user.save()
        return Response({'detail': 'Mot de passe changé avec succès.'})


class LogoutView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        response = Response({'detail': 'Déconnexion réussie.'})
        response.delete_cookie('refresh_token', path='/api/users/token/refresh/')
        return response


class ListeUtilisateursView(generics.ListAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAdminUser]


class UpdateDeleteUtilisateurView(generics.RetrieveUpdateDestroyAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAdminUser]


class CreerOpticienView(APIView):
    """Admin crée un compte opticien."""
    permission_classes = [IsOpticienOuAdmin]

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
    permission_classes = [permissions.IsAdminUser]

    def get_queryset(self):
        return User.objects.filter(role='client').order_by('-date_joined')
