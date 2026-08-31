"""Catalogue des verres et calcul du prix — côté serveur exclusivement.

Le montant d'une commande était reconstitué à partir de `rabais_famille` et
`prix_verres` envoyés par le navigateur : un client pouvait donc commander à
0 F CFA, voire à un montant négatif. Le client n'envoie plus désormais que des
**identifiants** ; tous les montants sont calculés ici, à partir de valeurs que
seul le serveur connaît.

Ce module est le miroir de `frontend/src/utils/ordonnanceUtils.ts`, qui reste
l'affichage : toute modification tarifaire doit être répercutée aux deux
endroits, mais seule cette version fait foi.
"""
from decimal import Decimal, ROUND_HALF_UP

from rest_framework.exceptions import ValidationError

# Prix en F CFA.
TYPES_VERRES = {
    'unifocal_simple': Decimal('15000'),
    'unifocal_mince':  Decimal('28000'),
    'torique':         Decimal('32000'),
    'progressif':      Decimal('55000'),
}

OPTIONS_VERRES = {
    'anti_reflets':   Decimal('8000'),
    'photochromique': Decimal('20000'),
    'antiblue':       Decimal('6000'),
    'uv':             Decimal('4000'),
}

# Paliers du rabais famille, alignés sur famille.models.GroupeFamille.taux_rabais().
RABAIS_MAX = Decimal('0.15')


def _arrondir(montant):
    return Decimal(montant).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)


def prix_verres(type_verre, options):
    """Prix total des verres à partir d'identifiants validés.

    Lève une ValidationError sur tout identifiant inconnu : accepter
    silencieusement un identifiant inconnu reviendrait à facturer 0.
    """
    if not type_verre:
        return Decimal('0.00')

    if type_verre not in TYPES_VERRES:
        raise ValidationError({'type_verre': "Type de verre inconnu."})

    total = TYPES_VERRES[type_verre]

    options = options or []
    if not isinstance(options, list):
        raise ValidationError({'options_verres': "Format attendu : liste d'identifiants."})

    inconnues = [o for o in options if o not in OPTIONS_VERRES]
    if inconnues:
        raise ValidationError({'options_verres': f"Options inconnues : {', '.join(map(str, inconnues))}."})

    # `set` : une option envoyée plusieurs fois ne doit être facturée qu'une fois.
    for option in set(options):
        total += OPTIONS_VERRES[option]

    return _arrondir(total)


def taux_rabais_famille(user):
    """Taux de rabais réellement acquis par l'utilisateur.

    Recalculé depuis la base : la valeur envoyée par le client n'est jamais lue.
    """
    from famille.models import GroupeFamille

    groupe = GroupeFamille.objects.filter(membres=user, actif=True).first()
    if groupe is None:
        return Decimal('0')

    taux = Decimal(str(groupe.taux_rabais()))
    # Ceinture et bretelles : même si `taux_rabais()` évoluait, le rabais ne peut
    # jamais dépasser le plafond ni devenir négatif.
    return max(Decimal('0'), min(taux, RABAIS_MAX))


def calculer_total(monture, user, type_verre=None, options=None):
    """Retourne (prix_total, prix_verres, taux_rabais) — tout en Decimal."""
    base = Decimal(str(monture.prix))
    if base <= 0:
        raise ValidationError({'detail': "Le prix de cette monture est invalide."})

    taux = taux_rabais_famille(user)
    verres = prix_verres(type_verre, options)

    total = _arrondir(base * (Decimal('1') - taux) + verres)
    if total <= 0:
        raise ValidationError({'detail': "Montant de commande invalide."})

    return total, verres, taux
