"""
Service SMS — Adaptateur pour les fournisseurs SMS africains.
Supporte : Orange API, Twilio, Africa's Talking, etc.
Configurer via variables d'environnement.
"""
import os
import logging
import requests

logger = logging.getLogger(__name__)

SMS_PROVIDER = os.environ.get('SMS_PROVIDER', 'mock')  # 'orange' | 'twilio' | 'africastalking' | 'mock'


def envoyer_sms(telephone: str, message: str) -> bool:
    """
    Envoie un SMS au numéro donné.
    Retourne True si succès, False sinon.
    """
    try:
        if SMS_PROVIDER == 'orange':
            return _envoyer_orange(telephone, message)
        elif SMS_PROVIDER == 'twilio':
            return _envoyer_twilio(telephone, message)
        elif SMS_PROVIDER == 'africastalking':
            return _envoyer_africastalking(telephone, message)
        else:
            # Mock — log le code en dev
            logger.info(f"[SMS MOCK] À: {telephone} | Message: {message}")
            return True
    except Exception as e:
        logger.error(f"Erreur envoi SMS à {telephone}: {e}")
        return False


def _envoyer_orange(telephone, message):
    """Orange API SMS — Burkina Faso / Afrique de l'Ouest"""
    token_url   = os.environ.get('ORANGE_TOKEN_URL')
    client_id   = os.environ.get('ORANGE_CLIENT_ID')
    client_secret = os.environ.get('ORANGE_CLIENT_SECRET')
    sender_name = os.environ.get('ORANGE_SENDER', 'OptiLunette')

    # Obtenir token OAuth2
    token_resp = requests.post(token_url, data={
        'grant_type': 'client_credentials',
        'client_id': client_id,
        'client_secret': client_secret,
    })
    token = token_resp.json().get('access_token')

    # Envoyer SMS
    sms_url = os.environ.get('ORANGE_SMS_URL', 'https://api.orange.com/smsmessaging/v1/outbound/tel%3A%2B22600000000/requests')
    resp = requests.post(sms_url, headers={
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
    }, json={
        'outboundSMSMessageRequest': {
            'address':            [f'tel:{telephone}'],
            'senderAddress':      f'tel:{sender_name}',
            'outboundSMSTextMessage': {'message': message},
        }
    })
    return resp.status_code == 201


def _envoyer_twilio(telephone, message):
    from twilio.rest import Client
    client = Client(os.environ.get('TWILIO_ACCOUNT_SID'), os.environ.get('TWILIO_AUTH_TOKEN'))
    msg = client.messages.create(
        body=message,
        from_=os.environ.get('TWILIO_FROM'),
        to=telephone,
    )
    return bool(msg.sid)


def _envoyer_africastalking(telephone, message):
    import africastalking
    africastalking.initialize(
        username=os.environ.get('AT_USERNAME'),
        api_key=os.environ.get('AT_API_KEY'),
    )
    sms = africastalking.SMS
    resp = sms.send(message, [telephone], sender_id=os.environ.get('AT_SENDER', 'OptiLunette'))
    return resp['SMSMessageData']['Message'] == 'Processed'
