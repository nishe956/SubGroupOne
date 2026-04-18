from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.core.mail import send_mail
from django.contrib.auth import get_user_model
from django.conf import settings

from commandes.models import Commande
from montures.models import Monture
from ordonnances.models import Ordonnance
from .models import Notification

User = get_user_model()

def create_and_send_notification(user, titre, message, type_notif, related_id=None):
    # Création en DB
    Notification.objects.create(
        user=user,
        titre=titre,
        message=message,
        type_notif=type_notif,
        related_id=related_id
    )
    
    # Envoi de l'email
    try:
        send_mail(
            subject=titre,
            message=message,
            from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@smartvision.com'),
            recipient_list=[user.email],
            fail_silently=True,
        )
    except Exception as e:
        print(f"Erreur d'envoi d'email à {user.email}: {e}")

@receiver(pre_save, sender=Commande)
def track_commande_statut(sender, instance, **kwargs):
    if instance.pk:
        # Check if it exists for status change tracking
        try:
            old_instance = Commande.objects.get(pk=instance.pk)
            instance._old_statut = old_instance.statut
        except Commande.DoesNotExist:
            instance._old_statut = None
    else:
        instance._old_statut = None

@receiver(post_save, sender=Commande)
def notify_commande(sender, instance, created, **kwargs):
    opticiens = User.objects.filter(role='opticien')
    admins = User.objects.filter(role='admin')
    client = instance.user

    if created:
        # Notifier les opticiens (Opérationnel)
        titre = f"Nouvelle commande #{instance.id}"
        message = f"Le client {client.email} vient de passer une commande pour la monture {instance.monture.nom}."
        for opt in opticiens:
            create_and_send_notification(opt, titre, message, 'commande', instance.id)
    else:
        # Vérification si le statut a changé
        if hasattr(instance, '_old_statut') and instance._old_statut != instance.statut:
            # Notifier le client (Suivi)
            titre_client = f"Mise à jour Commande #{instance.id}"
            message_client = f"Votre commande est passée au statut : {instance.get_statut_display()}."
            create_and_send_notification(client, titre_client, message_client, 'commande', instance.id)
            
            # Notifier l'admin (Gestion / Supervision)
            titre_admin = f"Gestion : Statut Commande #{instance.id} modifié"
            message_admin = f"Le statut de la commande #{instance.id} (Client: {client.email}) a été modifié en : {instance.get_statut_display()}."
            for adm in admins:
                create_and_send_notification(adm, titre_admin, message_admin, 'commande', instance.id)

@receiver(post_save, sender=Ordonnance)
def notify_ordonnance(sender, instance, created, **kwargs):
    if created:
        # Uniquement l'opticien pour le traitement opérationnel
        opticiens = User.objects.filter(role='opticien')
        client = instance.user
        titre = f"Nouvelle ordonnance scannée"
        message = f"Le client {client.email if client else 'Inconnu'} a scanné une nouvelle ordonnance."
        for opt in opticiens:
            create_and_send_notification(opt, titre, message, 'ordonnance', instance.id)

@receiver(post_save, sender=Monture)
def notify_monture_stock(sender, instance, created, **kwargs):
    opticiens = User.objects.filter(role='opticien')
    admins = User.objects.filter(role='admin')
    
    if created:
        # Notifier l'admin de l'ajout d'un nouveau produit (Gestion)
        titre = f"Gestion : Nouveau produit ajouté"
        message = f"Une nouvelle monture '{instance.nom}' ({instance.marque}) a été ajoutée au catalogue."
        for adm in admins:
            create_and_send_notification(adm, titre, message, 'stock', instance.id)

    if instance.stock <= 2:
        # Alerte stock critique pour l'opticien
        titre = f"Alerte de Stock : {instance.nom}"
        message = f"Attention, le stock pour la monture {instance.nom} ({instance.marque}) est devenu critique : {instance.stock} restant(s)."
        for opt in opticiens:
            create_and_send_notification(opt, titre, message, 'stock', instance.id)
