import 'package:flutter/material.dart';

/// Modèle produit (monture) — données mock ou injectées côté app.
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
  });

  final String id;
  final String name;

  /// Une des 9 catégories principales (libellé exact).
  final String category;

  /// `Homme`, `Femme` ou `Unisexe`.
  final String gender;

  final String description;
  final double priceEur;

  /// Photo produit (packagée dans `assets/products/`).
  final String imageAsset;

  /// Teinte pour l’overlay AR / accents si besoin.
  final List<Color> heroGradient;

  final String? reference;

  String get heroTag => 'product-hero-$id';
}
