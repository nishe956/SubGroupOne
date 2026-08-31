import datetime

from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from sms_otp.sms_service import envoyer_sms
from users.permissions import IsOpticienOuAdmin
from utils.audit import journaliser

from .models import CampagneMarketing, ConfigAutoAnniversaire, HistoriqueSMS
from .serializers import CampagneSerializer, HistoriqueSMSSerializer
from .tasks import rendre_message

User = get_user_model()

# Nombre maximal de destinataires d'un envoi collectif, pour éviter qu'un compte
# compromis ne vide le crédit SMS en une requête.
MAX_DESTINATAIRES_COLLECTIF = 500
LONGUEUR_MAX_SMS = 480  # ~3 segments


def clients_de(user):
    """Clients qu'un utilisateur a le droit de cibler.

    Un opticien ne peut atteindre que les clients ayant commandé chez lui.
    """
    if user.role == 'opticien':
        return User.objects.filter(
            role='client', commandes__monture__ajoute_par=user
        ).distinct()
    return User.objects.filter(role='client')


class ClientsAnniversaire(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        today = timezone.now().date()
        clients_qs = clients_de(request.user)

        upcoming = []
        for i in range(7):
            day = today + datetime.timedelta(days=i)
            matches = clients_qs.filter(
                date_naissance__month=day.month,
                date_naissance__day=day.day,
            )
            label = "Aujourd'hui" if i == 0 else ('Demain' if i == 1 else f'Dans {i} jours')
            for c in matches:
                upcoming.append({
                    'id': c.id,
                    'nom': c.get_full_name() or c.username,
                    'label': label,
                })
        return Response(upcoming)


class EnvoyerSouhaits(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def post(self, request, pk):
        # `User.objects.get(pk=pk)` permettait d'envoyer un SMS à n'importe quel
        # compte de la plateforme — y compris un administrateur — et d'énumérer
        # les utilisateurs existants via la réponse 404.
        client = clients_de(request.user).filter(pk=pk).first()
        if client is None:
            return Response({'detail': 'Client introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        if not client.telephone:
            return Response(
                {'detail': "Ce client n'a pas de numéro de téléphone."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        message = (
            f"OptiLunette vous souhaite un Joyeux Anniversaire "
            f"{client.first_name or client.username} ! 🎂\n"
            f"Profitez de 10% de réduction sur votre prochaine commande "
            f"aujourd'hui avec le code : ANNIV10"
        )

        sent = envoyer_sms(client.telephone, message)
        HistoriqueSMS.objects.create(
            destinataire=client,
            telephone=client.telephone,
            message=message,
            type_message='anniversaire',
            envoye=sent,
            envoye_par=request.user,
        )
        journaliser('sms_anniversaire', request.user, cible_id=client.pk, envoye=sent)

        return Response({'detail': "Message d'anniversaire envoyé !", 'message': message})


class EnvoyerSMSCollectif(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def post(self, request):
        message = (request.data.get('message') or '').strip()
        cible = request.data.get('cible', 'all')

        if not message:
            return Response({'detail': 'Message requis.'}, status=status.HTTP_400_BAD_REQUEST)
        if len(message) > LONGUEUR_MAX_SMS:
            return Response(
                {'detail': f'Message trop long (maximum {LONGUEUR_MAX_SMS} caractères).'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        queryset = clients_de(request.user).exclude(telephone='').filter(telephone__isnull=False)
        if cible == 'actifs':
            queryset = queryset.filter(is_active=True)

        destinataires = list(queryset[:MAX_DESTINATAIRES_COLLECTIF])

        count = 0
        historiques = []
        for client in destinataires:
            sent = envoyer_sms(client.telephone, message)
            historiques.append(HistoriqueSMS(
                destinataire=client,
                telephone=client.telephone,
                message=message,
                type_message='collectif',
                envoye=sent,
                envoye_par=request.user,
            ))
            if sent:
                count += 1
        HistoriqueSMS.objects.bulk_create(historiques)

        journaliser('sms_collectif', request.user, destinataires=len(destinataires), envoyes=count)
        return Response({'detail': f'{count} SMS envoyés.', 'nb_envoyes': count})


class HistoriqueSMSView(generics.ListAPIView):
    serializer_class = HistoriqueSMSSerializer
    permission_classes = [IsOpticienOuAdmin]

    def get_queryset(self):
        # `HistoriqueSMS.objects.all()` exposait à chaque opticien les numéros de
        # téléphone et le contenu des SMS de tous les autres opticiens.
        qs = HistoriqueSMS.objects.select_related('destinataire')
        if self.request.user.role == 'opticien':
            qs = qs.filter(envoye_par=self.request.user)
        return qs.order_by('-date_envoi')


class CampagnesView(generics.ListCreateAPIView):
    serializer_class = CampagneSerializer
    permission_classes = [IsOpticienOuAdmin]

    def get_queryset(self):
        qs = CampagneMarketing.objects.all()
        if self.request.user.role == 'opticien':
            qs = qs.filter(creee_par=self.request.user)
        return qs.order_by('-date_creation')

    def perform_create(self, serializer):
        serializer.save(creee_par=self.request.user)


class StatsMarketing(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        today = timezone.now().date()
        clients_qs = clients_de(request.user)

        sms_qs = HistoriqueSMS.objects.filter(envoye=True)
        campagnes_qs = CampagneMarketing.objects.filter(statut='active')
        if request.user.role == 'opticien':
            sms_qs = sms_qs.filter(envoye_par=request.user)
            campagnes_qs = campagnes_qs.filter(creee_par=request.user)

        return Response({
            'total_clients': clients_qs.count(),
            'anniversaires_aujourd_hui': clients_qs.filter(
                date_naissance__month=today.month, date_naissance__day=today.day
            ).count(),
            'sms_envoyes_total': sms_qs.count(),
            'campagnes_actives': campagnes_qs.count(),
        })


class ConfigAutoAnniversaireView(APIView):
    """Lire et modifier la config d'envoi automatique d'anniversaires."""
    permission_classes = [IsOpticienOuAdmin]

    def _serialiser(self, config, **extra):
        donnees = {
            'actif': config.actif,
            'message_template': config.message_template,
            'heure_envoi': config.heure_envoi.strftime('%H:%M'),
        }
        donnees.update(extra)
        return donnees

    def get(self, request):
        config, _ = ConfigAutoAnniversaire.objects.get_or_create(opticien=request.user)
        return Response(self._serialiser(config))

    def patch(self, request):
        config, _ = ConfigAutoAnniversaire.objects.get_or_create(opticien=request.user)

        if 'actif' in request.data:
            config.actif = bool(request.data['actif'])

        if 'message_template' in request.data:
            gabarit = str(request.data['message_template'])[:LONGUEUR_MAX_SMS]
            # Le gabarit était passé à str.format() : un jeton inconnu levait une
            # KeyError qui interrompait l'envoi pour TOUS les opticiens, et la
            # syntaxe de format donnait accès à la traversée d'attributs.
            # `rendre_message` n'accepte plus qu'une liste blanche de jetons.
            try:
                rendre_message(gabarit, prenom='Test')
            except ValueError as exc:
                return Response({'detail': str(exc)}, status=status.HTTP_400_BAD_REQUEST)
            config.message_template = gabarit

        if 'heure_envoi' in request.data:
            try:
                heure = datetime.datetime.strptime(
                    str(request.data['heure_envoi'])[:5], '%H:%M'
                ).time()
            except ValueError:
                return Response(
                    {'detail': "Heure invalide (format attendu : HH:MM)."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            config.heure_envoi = heure

        config.save()
        return Response(self._serialiser(config, detail='Configuration mise à jour.'))


class DeclenchemanualAnniversaires(APIView):
    """Déclenche l'envoi immédiatement, pour le seul compte appelant.

    La version précédente lançait la tâche globale : un opticien déclenchait donc
    les envois — et les coûts SMS — de tous ses concurrents.
    """
    permission_classes = [IsOpticienOuAdmin]

    def post(self, request):
        from .tasks import envoyer_anniversaires_auto

        nb = envoyer_anniversaires_auto(opticien=request.user)
        journaliser('anniversaires_declenches', request.user, envoyes=nb)
        return Response({'detail': f"{nb} message(s) d'anniversaire envoyé(s).", 'nb': nb})


class SegmentsClients(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def get(self, request):
        base_qs = clients_de(request.user)
        return Response([
            {'nom': 'Tous les clients',    'count': base_qs.count()},
            {'nom': 'Clients actifs',      'count': base_qs.filter(is_active=True).count()},
            {'nom': 'Avec téléphone',      'count': base_qs.exclude(telephone='')
                                                          .filter(telephone__isnull=False).count()},
            {'nom': 'Avec date naissance', 'count': base_qs.filter(date_naissance__isnull=False).count()},
        ])
