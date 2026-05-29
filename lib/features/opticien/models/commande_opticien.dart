import 'package:flutter/material.dart';

/// Statuts possibles d'une commande opticien.
enum StatutCommande { enAttente, validee, rejetee }

extension StatutCommandeExt on StatutCommande {
  String get label {
    switch (this) {
      case StatutCommande.enAttente:
        return 'En attente';
      case StatutCommande.validee:
        return 'Validée';
      case StatutCommande.rejetee:
        return 'Rejetée';
    }
  }

  Color get color {
    switch (this) {
      case StatutCommande.enAttente:
        return const Color(0xFFB8860B); // or foncé
      case StatutCommande.validee:
        return const Color(0xFF4A7C59); // vert sage
      case StatutCommande.rejetee:
        return const Color(0xFF8B3A3A); // rouge sombre
    }
  }

  Color get backgroundColor {
    switch (this) {
      case StatutCommande.enAttente:
        return const Color(0xFFFFF3CD);
      case StatutCommande.validee:
        return const Color(0xFFD4EDDA);
      case StatutCommande.rejetee:
        return const Color(0xFFF8D7DA);
    }
  }

  IconData get icon {
    switch (this) {
      case StatutCommande.enAttente:
        return Icons.hourglass_empty_rounded;
      case StatutCommande.validee:
        return Icons.check_circle_rounded;
      case StatutCommande.rejetee:
        return Icons.cancel_rounded;
    }
  }
}

/// Données OCR extraites d'une ordonnance.
class OrdonnanceDetail {
  const OrdonnanceDetail({
    required this.imageAsset,
    this.odSphere,
    this.odCylindre,
    this.odAxe,
    this.odAddition,
    this.ogSphere,
    this.ogCylindre,
    this.ogAxe,
    this.ogAddition,
    this.pd,
    this.medecin,
    this.dateOrdonnance,
  });

  /// Chemin de l'image de l'ordonnance (asset ou URL mock).
  final String imageAsset;

  // Œil droit (OD)
  final String? odSphere;
  final String? odCylindre;
  final String? odAxe;
  final String? odAddition;

  // Œil gauche (OG)
  final String? ogSphere;
  final String? ogCylindre;
  final String? ogAxe;
  final String? ogAddition;

  /// Écart pupillaire (PD) en mm.
  final String? pd;
  final String? medecin;
  final DateTime? dateOrdonnance;

  factory OrdonnanceDetail.fromJson(Map<String, dynamic> json) {
    return OrdonnanceDetail(
      imageAsset: json['imageAsset'] as String? ?? '',
      odSphere: json['odSphere'] as String?,
      odCylindre: json['odCylindre'] as String?,
      odAxe: json['odAxe'] as String?,
      odAddition: json['odAddition'] as String?,
      ogSphere: json['ogSphere'] as String?,
      ogCylindre: json['ogCylindre'] as String?,
      ogAxe: json['ogAxe'] as String?,
      ogAddition: json['ogAddition'] as String?,
      pd: json['pd'] as String?,
      medecin: json['medecin'] as String?,
      dateOrdonnance: json['dateOrdonnance'] != null
          ? DateTime.tryParse(json['dateOrdonnance'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'imageAsset': imageAsset,
        'odSphere': odSphere,
        'odCylindre': odCylindre,
        'odAxe': odAxe,
        'odAddition': odAddition,
        'ogSphere': ogSphere,
        'ogCylindre': ogCylindre,
        'ogAxe': ogAxe,
        'ogAddition': ogAddition,
        'pd': pd,
        'medecin': medecin,
        'dateOrdonnance': dateOrdonnance?.toIso8601String(),
      };
}

/// Informations assurance liées à une commande.
class AssuranceDetail {
  const AssuranceDetail({
    required this.nomAssureur,
    required this.numeroPriseEnCharge,
    required this.tauxRemboursement,
  });

  final String nomAssureur;
  final String numeroPriseEnCharge;

  /// Pourcentage de remboursement (ex: 80.0 pour 80%).
  final double tauxRemboursement;

  factory AssuranceDetail.fromJson(Map<String, dynamic> json) {
    return AssuranceDetail(
      nomAssureur: json['nomAssureur'] as String? ?? '',
      numeroPriseEnCharge: json['numeroPriseEnCharge'] as String? ?? '',
      tauxRemboursement:
          (json['tauxRemboursement'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'nomAssureur': nomAssureur,
        'numeroPriseEnCharge': numeroPriseEnCharge,
        'tauxRemboursement': tauxRemboursement,
      };
}

/// Modèle complet d'une commande vue par l'opticien.
class CommandeOpticien {
  const CommandeOpticien({
    required this.id,
    required this.nomClient,
    required this.contactClient,
    required this.nomMonture,
    required this.imageMonture,
    required this.prixMonture,
    required this.statut,
    required this.dateCommande,
    required this.ordonnance,
    this.assurance,
    this.commentaireRejet,
  });

  final String id;
  final String nomClient;
  final String contactClient;
  final String nomMonture;
  final String imageMonture;
  final double prixMonture;
  final StatutCommande statut;
  final DateTime dateCommande;
  final OrdonnanceDetail ordonnance;
  final AssuranceDetail? assurance;
  final String? commentaireRejet;

  /// Retourne une copie avec un nouveau statut et commentaire éventuel.
  CommandeOpticien copyWith({
    StatutCommande? statut,
    String? commentaireRejet,
  }) {
    return CommandeOpticien(
      id: id,
      nomClient: nomClient,
      contactClient: contactClient,
      nomMonture: nomMonture,
      imageMonture: imageMonture,
      prixMonture: prixMonture,
      statut: statut ?? this.statut,
      dateCommande: dateCommande,
      ordonnance: ordonnance,
      assurance: assurance,
      commentaireRejet: commentaireRejet ?? this.commentaireRejet,
    );
  }

  factory CommandeOpticien.fromJson(Map<String, dynamic> json) {
    return CommandeOpticien(
      id: json['id'] as String,
      nomClient: json['nomClient'] as String,
      contactClient: json['contactClient'] as String,
      nomMonture: json['nomMonture'] as String,
      imageMonture: json['imageMonture'] as String,
      prixMonture: (json['prixMonture'] as num).toDouble(),
      statut: StatutCommande.values.firstWhere(
        (s) => s.name == json['statut'],
        orElse: () => StatutCommande.enAttente,
      ),
      dateCommande: DateTime.parse(json['dateCommande'] as String),
      ordonnance: OrdonnanceDetail.fromJson(
          json['ordonnance'] as Map<String, dynamic>),
      assurance: json['assurance'] != null
          ? AssuranceDetail.fromJson(
              json['assurance'] as Map<String, dynamic>)
          : null,
      commentaireRejet: json['commentaireRejet'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nomClient': nomClient,
        'contactClient': contactClient,
        'nomMonture': nomMonture,
        'imageMonture': imageMonture,
        'prixMonture': prixMonture,
        'statut': statut.name,
        'dateCommande': dateCommande.toIso8601String(),
        'ordonnance': ordonnance.toJson(),
        'assurance': assurance?.toJson(),
        'commentaireRejet': commentaireRejet,
      };
}
