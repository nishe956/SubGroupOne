from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Commande
from .serializers import CommandeSerializer
from .emails import (
    envoyer_email_commande_recue,
    envoyer_email_commande_validee,
    envoyer_email_commande_rejetee,
)
from users.permissions import IsOpticienOuAdmin


class PasserCommande(generics.CreateAPIView):
    serializer_class = CommandeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        monture = serializer.validated_data['monture']

        if monture.stock <= 0:
            from rest_framework.exceptions import ValidationError
            raise ValidationError({'detail': 'Cette monture est en rupture de stock.'})

        rabais   = float(self.request.data.get('rabais_famille', 0))
        prix     = float(monture.prix) * (1 - rabais)
        opticien = monture.ajoute_par if monture.ajoute_par else None

        methode_paiement    = self.request.data.get('methode_paiement', '')
        telephone_paiement  = self.request.data.get('telephone_paiement', '')
        adresse_livraison   = self.request.data.get('adresse_livraison', '') or self.request.user.adresse
        latitude            = self.request.data.get('latitude')
        longitude           = self.request.data.get('longitude')
        type_verre          = self.request.data.get('type_verre', '')
        options_verres      = self.request.data.get('options_verres', [])
        prix_verres_raw     = self.request.data.get('prix_verres')
        prix_verres         = float(prix_verres_raw) if prix_verres_raw else None

        # Ajouter le prix des verres au total
        if prix_verres:
            prix += prix_verres

        compagnie_id = self.request.data.get('compagnie_assurance_id') or (
            self.request.user.compagnie_assurance_id
        )
        numero_police = self.request.data.get('numero_police') or self.request.user.numero_police or ''

        save_kwargs = dict(
            client=self.request.user,
            prix_total=prix,
            opticien=opticien,
            methode_paiement=methode_paiement,
            telephone_paiement=telephone_paiement,
            adresse_livraison=adresse_livraison,
            numero_assurance=numero_police,
            type_verre=type_verre,
            options_verres=options_verres if isinstance(options_verres, list) else [],
            prix_verres=prix_verres,
        )
        if latitude is not None:
            save_kwargs['latitude'] = float(latitude)
        if longitude is not None:
            save_kwargs['longitude'] = float(longitude)

        commande = serializer.save(**save_kwargs)

        # Décrémenter le stock
        monture.stock -= 1
        if monture.stock == 0:
            monture.disponible = False
        monture.save(update_fields=['stock', 'disponible'])

        # Créer automatiquement une demande de remboursement si le client a une assurance
        if compagnie_id:
            from assurance.models import CompagnieAssurance, DemandeRemboursement
            try:
                compagnie = CompagnieAssurance.objects.get(pk=compagnie_id, active=True)
                demande = DemandeRemboursement(
                    commande=commande,
                    compagnie=compagnie,
                    client=self.request.user,
                    numero_police=numero_police,
                    montant_total=commande.prix_total,
                )
                demande.calculer_montants()
                demande.save()
            except CompagnieAssurance.DoesNotExist:
                pass

        # Email de confirmation de réception
        envoyer_email_commande_recue(commande)


class ListeCommandes(generics.ListAPIView):
    serializer_class = CommandeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'client':
            return Commande.objects.filter(client=user).order_by('-date_commande')
        if user.role == 'opticien':
            return Commande.objects.filter(opticien=user).order_by('-date_commande')
        return Commande.objects.all().order_by('-date_commande')


class DetailCommande(generics.RetrieveAPIView):
    serializer_class = CommandeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'client':
            return Commande.objects.filter(client=user)
        return Commande.objects.all()


class GererCommande(APIView):
    permission_classes = [IsOpticienOuAdmin]

    def post(self, request, pk):
        try:
            commande = Commande.objects.get(pk=pk)
        except Commande.DoesNotExist:
            return Response({'detail': 'Commande introuvable'}, status=status.HTTP_404_NOT_FOUND)

        nouveau_statut = request.data.get('statut')
        statuts_valides = ['validee', 'rejetee', 'en_preparation', 'expediee', 'livree']

        if nouveau_statut not in statuts_valides:
            return Response(
                {'detail': f'Statut invalide. Choisir parmi : {statuts_valides}'},
                status=status.HTTP_400_BAD_REQUEST
            )

        commande.statut = nouveau_statut
        commande.notes = request.data.get('notes', commande.notes)
        commande.save()

        # Emails selon le statut
        if nouveau_statut == 'validee':
            envoyer_email_commande_validee(commande)
        elif nouveau_statut == 'rejetee':
            envoyer_email_commande_rejetee(commande)

        return Response({
            'detail': f'Commande mise à jour.',
            'commande': CommandeSerializer(commande).data,
        })


class AnnulerCommande(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            commande = Commande.objects.get(pk=pk, client=request.user)
        except Commande.DoesNotExist:
            return Response({'detail': 'Commande introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        if commande.statut not in ['en_attente']:
            return Response(
                {'detail': 'Seules les commandes en attente peuvent être annulées.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        commande.statut = 'rejetee'
        commande.notes = 'Annulée par le client'
        commande.save()

        # Remettre le stock
        commande.monture.stock += 1
        commande.monture.disponible = True
        commande.monture.save(update_fields=['stock', 'disponible'])

        envoyer_email_commande_rejetee(commande)

        return Response({'detail': 'Commande annulée.'})


class InitierPaiement(APIView):
    permission_classes = [permissions.IsAuthenticated]

    METHODES_VALIDES = ['carte_bancaire', 'orange_money', 'wave']

    def post(self, request, pk):
        try:
            commande = Commande.objects.get(pk=pk, client=request.user)
        except Commande.DoesNotExist:
            return Response({'detail': 'Commande introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        methode = request.data.get('methode', commande.methode_paiement or 'orange_money')

        if methode not in self.METHODES_VALIDES:
            return Response(
                {'detail': f'Méthode invalide. Choisir parmi : {self.METHODES_VALIDES}'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Mettre à jour la méthode si fournie
        if methode != commande.methode_paiement:
            commande.methode_paiement = methode
            commande.save(update_fields=['methode_paiement'])

        # TODO: intégrer les APIs réelles (Orange Money, Wave, etc.)
        instructions = {
            'orange_money': 'Composez *144*4*6# pour payer via Orange Money.',
            'wave':         'Ouvrez l\'app Wave et scannez le QR code ou composez *770*montant#.',
'carte_bancaire': 'Saisissez vos informations de carte sur la page de paiement sécurisée.',
        }

        return Response({
            'detail': 'Paiement initié.',
            'commande_id': commande.id,
            'montant': float(commande.prix_total),
            'methode': methode,
            'reference': f'PAY-{commande.id:06d}',
            'statut': 'pending',
            'instructions': instructions.get(methode, ''),
        })


class ConfirmerPaiement(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            commande = Commande.objects.get(pk=pk, client=request.user)
        except Commande.DoesNotExist:
            return Response({'detail': 'Commande introuvable.'}, status=status.HTTP_404_NOT_FOUND)

        reference = request.data.get('reference', '')

        # En prod : vérifier auprès du prestataire de paiement
        commande.statut = 'validee'
        commande.notes = f'Paiement confirmé — ref: {reference}'
        commande.save()

        return Response({
            'detail': 'Paiement confirmé.',
            'commande': CommandeSerializer(commande).data,
        })
