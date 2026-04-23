from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions, status, generics
from django.utils import timezone
from django.contrib.auth import get_user_model
from .models import HistoriqueSMS, CampagneMarketing, ConfigAutoAnniversaire
from .serializers import HistoriqueSMSSerializer, CampagneSerializer
from sms_otp.sms_service import envoyer_sms
from users.permissions import IsOpticienOuAdmin

User = get_user_model()


class ClientsAnniversaire(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        today = timezone.now().date()
        is_opticien = request.user.role == 'opticien'
        clients_qs = (
            User.objects.filter(role='client', commandes__monture__ajoute_par=request.user).distinct()
            if is_opticien else User.objects.filter(role='client')
        )
        # Anniversaires dans les 7 prochains jours (incluant aujourd'hui)
        from django.db.models import IntegerField, Value
        from django.db.models.functions import ExtractMonth, ExtractDay
        upcoming = []
        for i in range(7):
            day = today + __import__('datetime').timedelta(days=i)
            matches = clients_qs.filter(
                date_naissance__month=day.month,
                date_naissance__day=day.day,
            )
            for c in matches:
                label = 'Aujourd\'hui' if i == 0 else ('Demain' if i == 1 else f'Dans {i} jours')
                upcoming.append({'id': c.id, 'nom': c.get_full_name() or c.username, 'label': label})
        return Response(upcoming)


class EnvoyerSouhaits(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def post(self, request, pk):
        try:
            client = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({'detail': 'Client introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        message = (
            f"OptiLunette vous souhaite un Joyeux Anniversaire {client.first_name or client.username} ! 🎂\n"
            f"Profitez de 10% de réduction sur votre prochaine commande aujourd'hui avec le code : ANNIV10"
        )

        if client.telephone:
            sent = envoyer_sms(client.telephone, message)
            HistoriqueSMS.objects.create(
                destinataire=client,
                telephone=client.telephone,
                message=message,
                type_message='anniversaire',
                envoye=sent,
                envoye_par=request.user,
            )

        return Response({'detail': 'Message d\'anniversaire envoyé !', 'message': message})


class EnvoyerSMSCollectif(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def post(self, request):
        message = request.data.get('message', '')
        cible   = request.data.get('cible', 'all')

        if not message:
            return Response({'detail': 'Message requis.'}, status=status.HTTP_400_BAD_REQUEST)

        is_opticien = request.user.role == 'opticien'
        base_qs = (
            User.objects.filter(role='client', commandes__monture__ajoute_par=request.user).distinct()
            if is_opticien else User.objects.filter(role='client')
        )
        queryset = base_qs.filter(telephone__isnull=False)
        if cible == 'actifs':
            queryset = queryset.filter(is_active=True)

        count = 0
        for client in queryset:
            if client.telephone:
                sent = envoyer_sms(client.telephone, message)
                HistoriqueSMS.objects.create(
                    destinataire=client,
                    telephone=client.telephone,
                    message=message,
                    type_message='collectif',
                    envoye=sent,
                    envoye_par=request.user,
                )
                if sent: count += 1

        return Response({'detail': f'{count} SMS envoyés.', 'nb_envoyes': count})


class HistoriqueSMSView(generics.ListAPIView):
    serializer_class   = HistoriqueSMSSerializer
    permission_classes = [IsOpticienOuAdmin]
    queryset           = HistoriqueSMS.objects.all()


class CampagnesView(generics.ListCreateAPIView):
    serializer_class   = CampagneSerializer
    permission_classes = [IsOpticienOuAdmin]
    queryset           = CampagneMarketing.objects.all()

    def perform_create(self, serializer):
        serializer.save(creee_par=self.request.user)


class StatsMarketing(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        today    = timezone.now().date()
        total_clients = User.objects.filter(role='client').count()
        anniversaires = User.objects.filter(
            role='client',
            date_naissance__month=today.month,
        ).count()
        sms_envoyes = HistoriqueSMS.objects.filter(envoye=True).count()
        campagnes_actives = CampagneMarketing.objects.filter(statut='active').count()

        return Response({
            'total_clients': total_clients,
            'anniversaires_aujourd_hui': anniversaires,
            'sms_envoyes_total': sms_envoyes,
            'campagnes_actives': campagnes_actives,
        })


class ConfigAutoAnniversaireView(APIView):
    """Lire et modifier la config d'envoi automatique d'anniversaires."""
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        config, _ = ConfigAutoAnniversaire.objects.get_or_create(opticien=request.user)
        return Response({
            'actif': config.actif,
            'message_template': config.message_template,
            'heure_envoi': config.heure_envoi.strftime('%H:%M'),
        })

    def patch(self, request):
        config, _ = ConfigAutoAnniversaire.objects.get_or_create(opticien=request.user)
        if 'actif' in request.data:
            config.actif = bool(request.data['actif'])
        if 'message_template' in request.data:
            config.message_template = request.data['message_template']
        if 'heure_envoi' in request.data:
            config.heure_envoi = request.data['heure_envoi']
        config.save()
        return Response({
            'actif': config.actif,
            'message_template': config.message_template,
            'heure_envoi': config.heure_envoi.strftime('%H:%M'),
            'detail': 'Configuration mise à jour.',
        })


class DeclenchemanualAnniversaires(APIView):
    """Permet de déclencher l'envoi immédiatement (test / rattrapage)."""
    permission_classes = [IsOpticienOuAdmin]

    def post(self, request):
        from .tasks import envoyer_anniversaires_auto
        nb = envoyer_anniversaires_auto()
        return Response({'detail': f'{nb} message(s) d\'anniversaire envoyé(s).', 'nb': nb})


class SegmentsClients(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        is_opticien = request.user.role == 'opticien'
        base_qs = (
            User.objects.filter(role='client', commandes__monture__ajoute_par=request.user).distinct()
            if is_opticien else User.objects.filter(role='client')
        )
        total          = base_qs.count()
        actifs         = base_qs.filter(is_active=True).count()
        avec_tel       = base_qs.filter(telephone__isnull=False).exclude(telephone='').count()
        avec_naissance = base_qs.filter(date_naissance__isnull=False).count()

        return Response([
            {'nom': 'Tous les clients',    'count': total},
            {'nom': 'Clients actifs',      'count': actifs},
            {'nom': 'Avec téléphone',      'count': avec_tel},
            {'nom': 'Avec date naissance', 'count': avec_naissance},
        ])
