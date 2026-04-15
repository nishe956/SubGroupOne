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
    this.couleur,
    this.stock = 0,
  });

  final String id;
  final String name;

  /// Une des 9 catégories principales (libellé exact).
  final String category;

  /// `Homme`, `Femme` ou `Unisexe`.
  final String gender;

  final String description;
  final double priceEur;

  /// Photo produit (packagée dans `assets/products/` ou URL distante).
  final String imageAsset;

  /// Teinte pour l'overlay AR / accents si besoin.
  final List<Color> heroGradient;

  final String? reference; // marque
  final String? couleur;
  final int stock;

  String get heroTag => 'product-hero-$id';

  factory Product.fromJson(Map<String, dynamic> json) {
    // Mapping des champs Django (français) vers les propriétés Flutter (anglais)
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['nom'] ?? 'Sans nom',
      category: json['forme'] ?? 'Inconnu',
      gender: json['genre'] ?? 'Unisexe',
      description: json['description'] ?? '',
      priceEur: double.tryParse(json['prix']?.toString() ?? '0') ?? 0.0,
      imageAsset: json['image'] ?? 'assets/products/product_01.png',
      heroGradient: const [Colors.brown, Colors.brown], // Valeur par défaut
      reference: json['marque'],
      couleur: json['couleur'],
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }
}
