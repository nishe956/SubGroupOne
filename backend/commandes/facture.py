"""
Génération de la facture PDF d'une commande (reportlab).

Point d'entrée : generer_facture_pdf(commande) -> bytes
"""
from io import BytesIO
from django.utils.timezone import localtime
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
)

class _MontureSupprimee:
    """Repli utilisé quand la monture d'une commande a été supprimée (opticien effacé)."""
    marque = "Monture supprimée"
    nom = ""
    forme = ""
    couleur = ""


# Couleurs de la charte
VIOLET = colors.HexColor('#4f46e5')
GRIS_FONCE = colors.HexColor('#111827')
GRIS = colors.HexColor('#6b7280')
GRIS_CLAIR = colors.HexColor('#f9fafb')
BORDURE = colors.HexColor('#e5e7eb')

# Libellés lisibles pour les verres (miroir du frontend ordonnanceUtils.ts)
TYPES_VERRES_LABELS = {
    'unifocal_simple': 'Verres simples unifocaux',
    'unifocal_mince': 'Verres amincis (indice 1.6)',
    'torique': 'Verres toriques',
    'progressif': 'Verres progressifs',
}
OPTIONS_VERRES_LABELS = {
    'anti_reflets': 'Traitement anti-reflets',
    'photochromique': 'Verres photochromiques',
    'antiblue': 'Filtre lumière bleue',
    'uv': 'Protection UV 400',
}
METHODE_PAIEMENT_LABELS = {
    'carte_bancaire': 'Carte bancaire',
    'orange_money': 'Orange Money',
    'wave': 'Wave',
}


def _prix(montant):
    return f"{int(montant or 0):,} F CFA".replace(",", ".")


def _nom_client(commande):
    u = commande.client
    return u.get_full_name() or u.username


def generer_facture_pdf(commande) -> bytes:
    """Construit la facture PDF de la commande et renvoie les octets du fichier."""
    buffer = BytesIO()
    doc = SimpleDocTemplate(
        buffer, pagesize=A4,
        topMargin=18 * mm, bottomMargin=18 * mm,
        leftMargin=18 * mm, rightMargin=18 * mm,
        title=f"Facture CMD-{commande.id:06d}",
    )

    styles = getSampleStyleSheet()
    style_titre = ParagraphStyle('titre', parent=styles['Normal'], fontSize=22,
                                 textColor=VIOLET, fontName='Helvetica-Bold', leading=26)
    style_h = ParagraphStyle('h', parent=styles['Normal'], fontSize=9,
                             textColor=GRIS, fontName='Helvetica-Bold', spaceAfter=3)
    style_normal = ParagraphStyle('n', parent=styles['Normal'], fontSize=10,
                                  textColor=GRIS_FONCE, leading=14)
    style_petit = ParagraphStyle('p', parent=styles['Normal'], fontSize=8,
                                 textColor=GRIS, leading=11)

    elements = []
    ref = f"CMD-{commande.id:06d}"
    date = localtime(commande.date_commande).strftime("%d/%m/%Y à %H:%M")

    # Boutique vendeuse (le cas échéant)
    boutique = None
    if commande.opticien:
        boutique = getattr(commande.opticien, 'boutiqueopticien', None)
        if boutique is None:
            from boutique.models import BoutiqueOpticien
            boutique = BoutiqueOpticien.objects.filter(opticien=commande.opticien).first()

    # ── En-tête : marque à gauche, "FACTURE" + réf à droite ──
    vendeur_txt = "<b>Lunette Pro</b><br/>La vision au bout des doigts"
    if boutique:
        vendeur_txt = f"<b>{boutique.nom}</b>"
        if boutique.adresse:
            vendeur_txt += f"<br/>{boutique.adresse}"
        if boutique.telephone:
            vendeur_txt += f"<br/>Tél : {boutique.telephone}"
        if boutique.email:
            vendeur_txt += f"<br/>{boutique.email}"

    entete = Table([[
        Paragraph(vendeur_txt, style_normal),
        Paragraph(f"FACTURE<br/><font size=10 color='#6b7280'>{ref}</font>", style_titre),
    ]], colWidths=[100 * mm, 74 * mm])
    entete.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('ALIGN', (1, 0), (1, 0), 'RIGHT'),
    ]))
    elements += [entete, Spacer(1, 8 * mm)]

    # ── Bloc client + date ──
    infos = Table([[
        Paragraph("FACTURÉ À", style_h),
        Paragraph("DÉTAILS", style_h),
    ], [
        Paragraph(
            f"{_nom_client(commande)}<br/>"
            f"{commande.client.email or ''}<br/>"
            f"{commande.adresse_livraison or ''}",
            style_normal),
        Paragraph(
            f"Date : {date}<br/>"
            f"Paiement : {METHODE_PAIEMENT_LABELS.get(commande.methode_paiement, commande.methode_paiement or '—')}<br/>"
            f"Type : {'Lunettes de vue' if commande.type_commande == 'vue' else 'Style / Solaire'}",
            style_normal),
    ]], colWidths=[87 * mm, 87 * mm])
    infos.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 4),
    ]))
    elements += [infos, Spacer(1, 8 * mm)]

    # ── Tableau des lignes ──
    monture = commande.monture or _MontureSupprimee()
    lignes = [['Désignation', 'Détail', 'Montant']]

    prix_verres = float(commande.prix_verres or 0)
    prix_monture = float(commande.prix_total) - prix_verres

    lignes.append([
        Paragraph(f"<b>{monture.marque} — {monture.nom}</b>", style_normal),
        Paragraph(f"{monture.forme} · {monture.couleur}", style_petit),
        _prix(prix_monture),
    ])

    if commande.type_verre:
        détail_verre = OPTIONS_VERRES_LABELS
        opts = ", ".join(détail_verre.get(o, o) for o in (commande.options_verres or []))
        lignes.append([
            Paragraph(TYPES_VERRES_LABELS.get(commande.type_verre, commande.type_verre), style_normal),
            Paragraph(opts or "—", style_petit),
            _prix(prix_verres),
        ])

    tableau = Table(lignes, colWidths=[80 * mm, 54 * mm, 40 * mm])
    tableau.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), VIOLET),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 9),
        ('ALIGN', (2, 0), (2, -1), 'RIGHT'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ('LEFTPADDING', (0, 0), (-1, -1), 10),
        ('RIGHTPADDING', (0, 0), (-1, -1), 10),
        ('LINEBELOW', (0, 1), (-1, -1), 0.5, BORDURE),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, GRIS_CLAIR]),
    ]))
    elements += [tableau, Spacer(1, 4 * mm)]

    # ── Totaux ──
    total_lignes = []
    if float(commande.prix_verres or 0) and prix_monture:
        total_lignes.append(['Sous-total monture', _prix(prix_monture)])
        total_lignes.append(['Sous-total verres', _prix(prix_verres)])
    total_lignes.append(['TOTAL PAYÉ', _prix(commande.prix_total)])

    totaux = Table(total_lignes, colWidths=[134 * mm, 40 * mm])
    style_totaux = [
        ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('TEXTCOLOR', (0, 0), (-1, -2), GRIS),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        # Ligne du total
        ('BACKGROUND', (0, -1), (-1, -1), GRIS_CLAIR),
        ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
        ('FONTSIZE', (0, -1), (-1, -1), 12),
        ('TEXTCOLOR', (0, -1), (0, -1), GRIS_FONCE),
        ('TEXTCOLOR', (1, -1), (1, -1), VIOLET),
        ('LINEABOVE', (0, -1), (-1, -1), 1, VIOLET),
        ('TOPPADDING', (0, -1), (-1, -1), 8),
        ('BOTTOMPADDING', (0, -1), (-1, -1), 8),
        ('LEFTPADDING', (0, 0), (-1, -1), 10),
        ('RIGHTPADDING', (0, 0), (-1, -1), 10),
    ]
    totaux.setStyle(TableStyle(style_totaux))
    elements += [totaux, Spacer(1, 14 * mm)]

    # ── Pied de page ──
    elements.append(Paragraph(
        "Cette facture vaut preuve d'achat. Conservez-la précieusement.<br/>"
        "Pour toute question, contactez votre opticien.",
        style_petit))
    elements.append(Spacer(1, 3 * mm))
    elements.append(Paragraph(
        f"Facture générée le {localtime(commande.date_commande).strftime('%d/%m/%Y')} — Lunette Pro",
        ParagraphStyle('foot', parent=style_petit, textColor=GRIS, fontSize=7)))

    doc.build(elements)
    pdf = buffer.getvalue()
    buffer.close()
    return pdf
