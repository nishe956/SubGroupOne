from django.db import transaction
from django.db.models import F
from rest_framework import generics, permissions, status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from users.permissions import CompteUtilisable, IsOpticienOuAdmin
from utils.audit import journaliser

from .emails import (
    envoyer_email_commande_recue,
    envoyer_email_commande_rejetee,
    envoyer_email_commande_validee,
)
from .models import Commande
from .serializers import CommandeSerializer
from .tarifs import calculer_total

# Transitions autorisées : une commande ne peut plus revenir à un état
# antérieur. Sans machine à états, une commande livrée ou rejetée pouvait être
# ramenée à « validée ».
TRANSITIONS = {
    'en_attente':     {'validee', 'rejetee'},
    'validee':        {'en_preparation', 'rejetee'},
    'en_preparation': {'expediee', 'livree', 'rejetee'},
    'expediee':       {'livree'},
    'livree':         set(),
    'rejetee':        set(),
}


def _decrementer_stock(monture):
    """Décrément atomique et conditionnel du stock.

    `monture.stock -= 1; monture.save()` lisait puis écrivait sans verrou : N
    requêtes concurrentes sur la dernière unité passaient toutes le test de
    disponibilité et créaient N commandes.
    """
    lignes = (
        type(monture).objects
        .filter(pk=monture.pk, stock__gt=0)
        .update(stock=F('stock') - 1)
    )
    if not lignes:
        raise ValidationError({'detail': 'Cette monture est en rupture de stock.'})
    type(monture).objects.filter(pk=monture.pk, stock=0).update(disponible=False)


class PasserCommande(generics.CreateAPIView):
    serializer_class = CommandeSerializer
    permission_classes = [CompteUtilisable]

    @transaction.atomic
    def perform_create(self, serializer):
        user = self.request.user
        monture = serializer.validated_data['monture']

        # Sécurité : le client ne peut rattacher qu'une de ses propres ordonnances.
        ordonnance = serializer.validated_data.get('ordonnance')
        if ordonnance and ordonnance.client_id != user.id:
            raise ValidationError({'ordonnance': "Cette ordonnance ne vous appartient pas."})

        donnees = self.request.data
        type_commande = donnees.get('type_commande', 'vue')
        type_commande = type_commande if type_commande in ('vue', 'style') else 'vue'

        type_verre = donnees.get('type_verre') or ''
        options_verres = donnees.get('options_verres') or []

        # Prix intégralement recalculé côté serveur : ni le rabais ni le prix des
        # verres ne sont lus depuis la requête.
        prix_total, prix_verres, taux_rabais = calculer_total(
            monture, user, type_verre=type_verre or None, options=options_verres,
        )

        # Questionnaire de conception : dictionnaire de réponses libres.
        conception = donnees.get('conception_verres') or {}
        if not isinstance(conception, dict):
            conception = {}

        methode_paiement = donnees.get('methode_paiement', '')
        if methode_paiement and methode_paiement not in dict(Commande.METHODE_PAIEMENT_CHOICES):
            raise ValidationError({'methode_paiement': 'Méthode de paiement inconnue.'})

        save_kwargs = dict(
            client=user,
            prix_total=prix_total,
            prix_verres=prix_verres or None,
            opticien=monture.ajoute_par,
            type_commande=type_commande,
            methode_paiement=methode_paiement,
            telephone_paiement=str(donnees.get('telephone_paiement', ''))[:20],
            adresse_livraison=donnees.get('adresse_livraison', '') or user.adresse,
            numero_assurance=str(donnees.get('numero_police') or user.numero_police or '')[:100],
            type_verre=type_verre,
            options_verres=list(options_verres) if isinstance(options_verres, list) else [],
            conception_verres=conception,
        )

        for champ in ('latitude', 'longitude'):
            valeur = donnees.get(champ)
            if valeur in (None, ''):
                continue
            try:
                save_kwargs[champ] = float(valeur)
            except (TypeError, ValueError):
                raise ValidationError({champ: 'Coordonnée invalide.'})

        # Le stock est réservé AVANT la création : dans la transaction, un échec
        # de création annule automatiquement la réservation.
        _decrementer_stock(monture)
        commande = serializer.save(**save_kwargs)

        journaliser('commande_creee', user, commande_id=commande.pk,
                    montant=str(prix_total), rabais=str(taux_rabais))

        # L'email part une fois la transaction confirmée : inutile de notifier le
        # client d'une commande qui serait annulée par un rollback.
        transaction.on_commit(lambda: envoyer_email_commande_recue(commande))


class ListeCommandes(generics.ListAPIView):
    serializer_class = CommandeSerializer
    permission_classes = [CompteUtilisable]

    def get_queryset(self):
        user = self.request.user
        qs = Commande.objects.select_related('client', 'monture', 'ordonnance')
        if user.role == 'client':
            return qs.filter(client=user).order_by('-date_commande')
        if user.role == 'opticien':
            return qs.filter(opticien=user).order_by('-date_commande')
        return qs.all().order_by('-date_commande')


class DetailCommande(generics.RetrieveAPIView):
    serializer_class = CommandeSerializer
    permission_classes = [CompteUtilisable]

    def get_queryset(self):
        user = self.request.user
        qs = Commande.objects.select_related('client', 'monture', 'ordonnance')
        if user.role == 'client':
            return qs.filter(client=user)
        if user.role == 'opticien':
            # Un opticien accédait auparavant à TOUTE commande, avec l'ordonnance
            # (donnée de santé), l'adresse et les coordonnées GPS du client.
            return qs.filter(opticien=user)
        return qs.all()


class GererCommande(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def post(self, request, pk):
        # Un opticien ne gère que les commandes qui lui sont rattachées ; l'admin, toutes.
        qs = Commande.objects.all()
        if request.user.role == 'opticien':
            qs = qs.filter(opticien=request.user)
        try:
            commande = qs.get(pk=pk)
        except Commande.DoesNotExist:
            return Response({'detail': 'Commande introuvable'}, status=status.HTTP_404_NOT_FOUND)

        nouveau_statut = request.data.get('statut')
        if nouveau_statut not in TRANSITIONS:
            return Response(
                {'detail': f'Statut invalide. Choisir parmi : {sorted(TRANSITIONS)}'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if nouveau_statut not in TRANSITIONS[commande.statut]:
            return Response(
                {'detail': f"Transition impossible depuis « {commande.statut} »."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        ancien = commande.statut
        commande.statut = nouveau_statut
        commande.notes = str(request.data.get('notes', commande.notes))[:2000]
        commande.save(update_fields=['statut', 'notes', 'date_mise_a_jour'])

        journaliser('commande_statut', request.user, commande_id=commande.pk,
                    ancien=ancien, nouveau=nouveau_statut)

        if nouveau_statut == 'validee':
            envoyer_email_commande_validee(commande)
        elif nouveau_statut == 'rejetee':
            envoyer_email_commande_rejetee(commande)

        return Response({
            'detail': 'Commande mise à jour.',
            'commande': CommandeSerializer(commande).data,
        })


class AnnulerCommande(APIView):
    permission_classes = [CompteUtilisable]

    @transaction.atomic
    def post(self, request, pk):
        # `select_for_update` : deux annulations concurrentes de la même commande
        # recréditaient chacune une unité de stock.
        commande = (
            Commande.objects
            .select_for_update()
            .filter(pk=pk, client=request.user)
            .first()
        )
        if commande is None:
            return Response({'detail': 'Commande introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        if commande.statut != 'en_attente':
            return Response(
                {'detail': 'Seules les commandes en attente peuvent être annulées.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        commande.statut = 'rejetee'
        commande.notes = 'Annulée par le client'
        commande.save(update_fields=['statut', 'notes', 'date_mise_a_jour'])

        if commande.monture_id:
            type(commande.monture).objects.filter(pk=commande.monture_id).update(
                stock=F('stock') + 1, disponible=True,
            )

        journaliser('commande_annulee', request.user, commande_id=commande.pk)
        transaction.on_commit(lambda: envoyer_email_commande_rejetee(commande))

        return Response({'detail': 'Commande annulée.'})


class InitierPaiement(APIView):
    """Prépare le paiement d'une commande.

    Cet endpoint ne fait qu'enregistrer la méthode choisie et renvoyer les
    instructions correspondantes. Il ne change JAMAIS le statut de la commande :
    seul un webhook signé du prestataire de paiement pourra le faire, une fois
    l'intégration réalisée.
    """
    permission_classes = [CompteUtilisable]

    METHODES_VALIDES = ['carte_bancaire', 'orange_money', 'wave']

    def post(self, request, pk):
        try:
            commande = Commande.objects.get(pk=pk, client=request.user)
        except Commande.DoesNotExist:
            return Response({'detail': 'Commande introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        if commande.statut != 'en_attente':
            return Response(
                {'detail': "Cette commande n'est plus en attente de paiement."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        methode = request.data.get('methode', commande.methode_paiement or 'orange_money')
        if methode not in self.METHODES_VALIDES:
            return Response(
                {'detail': f'Méthode invalide. Choisir parmi : {self.METHODES_VALIDES}'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if methode != commande.methode_paiement:
            commande.methode_paiement = methode
            commande.save(update_fields=['methode_paiement'])

        instructions = {
            'orange_money':   'Composez *144*4*6# pour payer via Orange Money.',
            'wave':           "Ouvrez l'app Wave et scannez le QR code ou composez *770*montant#.",
            'carte_bancaire': 'Le paiement par carte sera disponible prochainement.',
        }

        journaliser('paiement_initie', request.user, commande_id=commande.pk, methode=methode)

        return Response({
            'detail': 'Paiement initié.',
            'commande_id': commande.id,
            'montant': float(commande.prix_total),
            'methode': methode,
            'reference': f'PAY-{commande.id:06d}',
            'statut': 'pending',
            'instructions': instructions.get(methode, ''),
        })


# NOTE DE SÉCURITÉ — ConfirmerPaiement a été supprimé.
#
# L'endpoint POST /api/commandes/<pk>/paiement/confirmer/ passait la commande à
# « validee » sur simple demande du client, avec une référence de transaction
# qu'il fournissait lui-même et qui n'était jamais vérifiée : n'importe quel
# client pouvait se faire livrer gratuitement.
#
# Tant qu'aucun prestataire n'est intégré, la validation d'un paiement se fait
# depuis le back-office opticien (GererCommande), après encaissement constaté.
#
# À l'intégration du prestataire, la confirmation devra :
#   1. arriver par un webhook du prestataire, jamais depuis le navigateur ;
#   2. être authentifiée par signature HMAC de la charge utile ;
#   3. porter une clé d'idempotence pour rejeter les rejeux ;
#   4. vérifier que le montant encaissé correspond à `commande.prix_total` ;
#   5. respecter la machine à états `TRANSITIONS` définie plus haut.
