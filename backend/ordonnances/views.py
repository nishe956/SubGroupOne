import os
import tempfile

from django.conf import settings
from django.db.models import Q
from django.http import FileResponse, Http404
from rest_framework import generics, permissions, status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from users.permissions import CompteUtilisable
from utils.audit import journaliser
from utils.throttles import ThrottleOCR
from utils.validators import extension_sure, valider_fichier_image_ou_pdf, valider_image_seulement

from .models import Ordonnance
from .ocr import analyser_ordonnance
from .serializers import OrdonnanceSerializer

EXTENSIONS_IMAGE = ('.jpg', '.jpeg', '.png', '.webp')


def ordonnances_visibles(user):
    """Ordonnances qu'un utilisateur a le droit de consulter.

    - client   : les siennes ;
    - opticien : uniquement celles rattachées à une commande qui lui revient.
                 Auparavant, tout opticien lisait l'intégralité des ordonnances
                 du réseau, c'est-à-dire les données de santé de tous les clients ;
    - admin    : toutes.
    """
    qs = Ordonnance.objects.select_related('client')
    if user.role == 'client':
        return qs.filter(client=user)
    if user.role == 'opticien':
        return qs.filter(
            Q(commande__opticien=user) | Q(commande__monture__ajoute_par=user)
        ).distinct()
    return qs


class AjouterOrdonnance(generics.CreateAPIView):
    serializer_class = OrdonnanceSerializer
    permission_classes = [CompteUtilisable]
    parser_classes = [MultiPartParser, FormParser]
    # Chaque ordonnance déclenche un appel facturé au fournisseur d'IA.
    throttle_classes = [ThrottleOCR]

    def perform_create(self, serializer):
        fichier = self.request.FILES.get('image')
        if not fichier:
            from rest_framework.exceptions import ValidationError
            raise ValidationError({'image': "Un fichier d'ordonnance est requis."})

        valider_fichier_image_ou_pdf(fichier)
        instance = serializer.save(client=self.request.user)
        journaliser('ordonnance_creee', self.request.user, ordonnance_id=instance.pk)

        # Lance l'OCR après la sauvegarde. `.path` n'existe pas sur un stockage
        # objet : on passe systématiquement par un fichier temporaire local.
        self._analyser(instance)

    def _analyser(self, instance):
        if not instance.image:
            return

        extension = extension_sure(instance.image.name, EXTENSIONS_IMAGE)
        if extension is None:
            return  # PDF ou format non pris en charge par l'OCR : on garde le fichier tel quel.

        chemin_temp = None
        try:
            with tempfile.NamedTemporaryFile(suffix=extension, delete=False) as tmp:
                with instance.image.open('rb') as source:
                    for chunk in source.chunks():
                        tmp.write(chunk)
                chemin_temp = tmp.name

            resultat = analyser_ordonnance(chemin_temp)
            if resultat['succes'] and resultat['valeurs_optiques']:
                v = resultat['valeurs_optiques']
                Ordonnance.objects.filter(pk=instance.pk).update(
                    oeil_droit_sphere=v.get('oeil_droit_sphere'),
                    oeil_droit_cylindre=v.get('oeil_droit_cylindre'),
                    oeil_droit_axe=v.get('oeil_droit_axe'),
                    oeil_gauche_sphere=v.get('oeil_gauche_sphere'),
                    oeil_gauche_cylindre=v.get('oeil_gauche_cylindre'),
                    oeil_gauche_axe=v.get('oeil_gauche_axe'),
                )
        except Exception:
            # L'ordonnance reste enregistrée même si l'OCR échoue ; le détail est
            # journalisé par le gestionnaire d'exceptions, jamais renvoyé au client.
            import logging
            logging.getLogger(__name__).exception("Échec OCR ordonnance %s", instance.pk)
        finally:
            if chemin_temp and os.path.exists(chemin_temp):
                os.remove(chemin_temp)


class ScannerOrdonnance(APIView):
    """Le client envoie une image d'ordonnance ; l'IA extrait les valeurs optiques."""
    permission_classes = [CompteUtilisable]
    parser_classes = [MultiPartParser, FormParser]
    throttle_classes = [ThrottleOCR]

    def post(self, request):
        if 'image' not in request.FILES:
            return Response({'erreur': 'Aucune image fournie'}, status=status.HTTP_400_BAD_REQUEST)

        image = request.FILES['image']

        # Valide le contenu réel du fichier (signature magique, taille, dimensions)
        # avant tout traitement.
        valider_image_seulement(image)

        # Le nom fourni par le client n'est jamais utilisé pour construire un
        # chemin : on ne conserve que l'extension, dans un fichier temporaire sûr.
        extension = extension_sure(image.name, EXTENSIONS_IMAGE)
        if extension is None:
            return Response({'erreur': 'Format non supporté.'}, status=status.HTTP_400_BAD_REQUEST)

        with tempfile.NamedTemporaryFile(suffix=extension, delete=False) as tmp:
            for chunk in image.chunks():
                tmp.write(chunk)
            chemin_temp = tmp.name

        try:
            resultat = analyser_ordonnance(chemin_temp)
        finally:
            os.remove(chemin_temp)

        if not resultat['succes']:
            # Le détail de l'erreur (URL de l'API tierce, trace du SDK) reste côté
            # serveur : il était auparavant renvoyé tel quel au client.
            import logging
            logging.getLogger(__name__).error("Échec OCR : %s", resultat['erreur'])
            return Response(
                {'erreur': "L'analyse automatique a échoué. Saisissez les valeurs manuellement."},
                status=status.HTTP_502_BAD_GATEWAY,
            )

        valeurs = resultat['valeurs_optiques']
        ordonnance = Ordonnance.objects.create(
            client=request.user,
            image=image,
            oeil_droit_sphere=valeurs['oeil_droit_sphere'],
            oeil_droit_cylindre=valeurs['oeil_droit_cylindre'],
            oeil_droit_axe=valeurs['oeil_droit_axe'],
            oeil_gauche_sphere=valeurs['oeil_gauche_sphere'],
            oeil_gauche_cylindre=valeurs['oeil_gauche_cylindre'],
            oeil_gauche_axe=valeurs['oeil_gauche_axe'],
        )
        journaliser('ordonnance_scannee', request.user, ordonnance_id=ordonnance.pk)

        return Response({
            'message': 'Ordonnance scannée avec succès',
            'ordonnance_id': ordonnance.id,
            'valeurs_extraites': valeurs,
        })


class ListeOrdonnances(generics.ListAPIView):
    serializer_class = OrdonnanceSerializer
    permission_classes = [CompteUtilisable]

    def get_queryset(self):
        return ordonnances_visibles(self.request.user).order_by('-date_upload')


class DetailOrdonnance(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = OrdonnanceSerializer
    permission_classes = [CompteUtilisable]

    def get_queryset(self):
        return ordonnances_visibles(self.request.user)

    def check_object_permissions(self, request, obj):
        super().check_object_permissions(request, obj)
        # Seuls le propriétaire et l'admin peuvent modifier ou supprimer une
        # ordonnance : l'opticien y a un accès en lecture pour fabriquer les
        # verres, pas un droit d'écriture sur un document médical.
        if request.method not in permissions.SAFE_METHODS:
            if request.user.role != 'admin' and obj.client_id != request.user.id:
                from rest_framework.exceptions import PermissionDenied
                raise PermissionDenied("Vous ne pouvez modifier que vos propres ordonnances.")

    def perform_destroy(self, instance):
        journaliser('ordonnance_supprimee', self.request.user, ordonnance_id=instance.pk)
        super().perform_destroy(instance)


class ValiderOrdonnance(APIView):
    permission_classes = [CompteUtilisable]

    def post(self, request, pk):
        if request.user.role not in ('opticien', 'admin'):
            return Response({'erreur': 'Permission refusée'}, status=status.HTTP_403_FORBIDDEN)

        ordonnance = ordonnances_visibles(request.user).filter(pk=pk).first()
        if ordonnance is None:
            return Response({'erreur': 'Ordonnance introuvable'}, status=status.HTTP_404_NOT_FOUND)

        ordonnance.validee = True
        ordonnance.save(update_fields=['validee'])
        journaliser('ordonnance_validee', request.user, ordonnance_id=ordonnance.pk)
        return Response({'message': 'Ordonnance validée avec succès'})


class TelechargerOrdonnance(APIView):
    """Sert l'image d'une ordonnance de façon authentifiée, avec contrôle d'accès.

    C'est le SEUL chemin d'accès aux documents médicaux : la route `/media/` ne
    les expose plus (voir config/urls.py).
    """
    permission_classes = [CompteUtilisable]

    def get(self, request, pk):
        ordonnance = ordonnances_visibles(request.user).filter(pk=pk).first()
        if ordonnance is None or not ordonnance.image:
            raise Http404

        journaliser('ordonnance_consultee', request.user, ordonnance_id=ordonnance.pk)

        response = FileResponse(ordonnance.image.open('rb'))
        # `no-store` : aucun cache navigateur ni intermédiaire sur une donnée de santé.
        response['Cache-Control'] = 'private, no-store, max-age=0'
        response['Content-Disposition'] = f'inline; filename="ordonnance-{ordonnance.pk}"'
        return response
