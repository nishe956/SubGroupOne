import 'package:flutter/material.dart';

import '../../core/api/api_config.dart';

/// Modèle produit (monture).
/// Peut être construit à partir de données locales (mock) ou de l'API Django.
@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.gender,
    required this.description,
    required this.priceEur,
    required this.imageAsset,
    required this.heroGradient,
    this.reference,
    this.marque,
    this.couleur,
    this.stock,
    this.disponible = true,
    this.backendId,
  });

  final String id;
  final String name;

  /// Une des 9 catégories principales (libellé exact humain).
  final String category;

  /// `Homme`, `Femme` ou `Unisexe`.
  final String gender;

  final String description;
  final double priceEur;

  /// Photo produit (chemin asset local ou URL réseau).
  final String imageAsset;

  /// Teinte pour l'overlay AR / accents si besoin.
  final List<Color> heroGradient;

  final String? reference;
  final String? marque;
  final String? couleur;
  final int? stock;
  final bool disponible;

  /// ID numérique du backend (pour les appels API).
  final int? backendId;

  String get heroTag => 'product-hero-$id';

  /// Indique si l'image provient du réseau (URL backend).
  bool get isNetworkImage =>
      imageAsset.startsWith('http://') || imageAsset.startsWith('https://');

  // ── Couleurs par défaut pour le gradient selon la couleur texte ────

  static List<Color> _gradientFromCouleur(String? couleur) {
    if (couleur == null) return [const Color(0xFF8A6B4F), const Color(0xFFB89A7A)];
    final c = couleur.toLowerCase();
    if (c.contains('or') || c.contains('gold') || c.contains('doré')) {
      return [const Color(0xFF8A6B4F), const Color(0xFFF4EFEA)];
    }
    if (c.contains('argent') || c.contains('silver') || c.contains('titane')) {
      return [const Color(0xFFB89A7A), const Color(0xFFD9C5B2)];
    }
    if (c.contains('noir') || c.contains('black')) {
      return [const Color(0xFF4A3A2A), const Color(0xFF8A6B4F)];
    }
    if (c.contains('rose')) {
      return [const Color(0xFFB89A7A), const Color(0xFFD9C5B2)];
    }
    return [const Color(0xFF8A6B4F), const Color(0xFFB89A7A)];
  }

  /// Construit un [Product] depuis un JSON de l'API Django.
  factory Product.fromApi(Map<String, dynamic> json) {
    final id = json['id'];
    final couleur = json['couleur'] as String?;

    // Image : URL complète si c'est un chemin relatif du backend
    String imageUrl = '';
    final rawImage = json['image'];
    if (rawImage != null && rawImage is String && rawImage.isNotEmpty) {
      if (rawImage.startsWith('http')) {
        imageUrl = rawImage;
      } else {
        imageUrl = '${ApiConfig.baseUrl}$rawImage';
      }
    }

    return Product(
      id: id.toString(),
      backendId: id is int ? id : int.tryParse(id.toString()),
      name: json['nom'] as String? ?? '',
      category: json['forme_display'] as String? ?? json['forme'] as String? ?? '',
      gender: json['genre_display'] as String? ?? 'Unisexe',
      description: json['description'] as String? ?? '',
      priceEur: (json['prix'] is String)
          ? double.tryParse(json['prix'] as String) ?? 0
          : (json['prix'] as num?)?.toDouble() ?? 0,
      imageAsset: imageUrl,
      heroGradient: _gradientFromCouleur(couleur),
      reference: (json['reference'] as String?)?.isNotEmpty == true
          ? json['reference'] as String
          : null,
      marque: json['marque'] as String?,
      couleur: couleur,
      stock: json['stock'] as int?,
      disponible: json['disponible'] as bool? ?? true,
    );
  }

  /// Convertit en JSON pour envoi vers l'API.
  Map<String, dynamic> toApiJson() => {
        'nom': name,
        'marque': marque ?? '',
        'prix': priceEur,
        'forme': _categoryToForme(category),
        'genre': _genderToGenre(gender),
        'couleur': couleur ?? '',
        'reference': reference ?? '',
        'description': description,
        'stock': stock ?? 0,
        'disponible': disponible,
      };

  static String _categoryToForme(String category) {
    const mapping = {
      'Lunettes de vue': 'lunettes_de_vue',
      'Lunettes de soleil': 'lunettes_de_soleil',
      'Anti-lumière bleue': 'anti_lumiere_bleue',
      'Rondes': 'ronde',
      'Rectangulaires': 'rectangulaire',
      'Carrées': 'carree',
      'Œil de chat (ou Cat-eye)': 'oeil_de_chat',
      'Aviateur': 'aviateur',
      'Oversize': 'oversize',
      'Ovale': 'ovale',
    };
    return mapping[category] ?? 'ronde';
  }

  static String _genderToGenre(String gender) {
    const mapping = {
      'Homme': 'homme',
      'Femme': 'femme',
      'Unisexe': 'unisexe',
    };
    return mapping[gender] ?? 'unisexe';
  }
}
