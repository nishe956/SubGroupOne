/// Modèle d'une monture gérée par l'opticien dans son catalogue.
class MontureOpticien {
  const MontureOpticien({
    required this.id,
    required this.nom,
    required this.marque,
    required this.prix,
    required this.description,
    required this.categorie,
    required this.couleur,
    required this.stock,
    required this.estActive,
    this.imageAsset,
    this.reference,
  });

  final String id;
  final String nom;
  final String marque;
  final double prix;
  final String description;
  final String categorie;
  final String couleur;
  final int stock;

  /// Indique si la monture est visible dans le catalogue client.
  final bool estActive;

  /// Chemin de l'image locale ou URL (null si aucune photo uploadée).
  final String? imageAsset;
  final String? reference;

  /// Retourne une copie modifiée.
  MontureOpticien copyWith({
    String? nom,
    String? marque,
    double? prix,
    String? description,
    String? categorie,
    String? couleur,
    int? stock,
    bool? estActive,
    String? imageAsset,
    String? reference,
  }) {
    return MontureOpticien(
      id: id,
      nom: nom ?? this.nom,
      marque: marque ?? this.marque,
      prix: prix ?? this.prix,
      description: description ?? this.description,
      categorie: categorie ?? this.categorie,
      couleur: couleur ?? this.couleur,
      stock: stock ?? this.stock,
      estActive: estActive ?? this.estActive,
      imageAsset: imageAsset ?? this.imageAsset,
      reference: reference ?? this.reference,
    );
  }

  factory MontureOpticien.fromJson(Map<String, dynamic> json) {
    return MontureOpticien(
      id: json['id'] as String,
      nom: json['nom'] as String,
      marque: json['marque'] as String,
      prix: (json['prix'] as num).toDouble(),
      description: json['description'] as String,
      categorie: json['categorie'] as String,
      couleur: json['couleur'] as String,
      stock: json['stock'] as int,
      estActive: json['estActive'] as bool? ?? true,
      imageAsset: json['imageAsset'] as String?,
      reference: json['reference'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'marque': marque,
        'prix': prix,
        'description': description,
        'categorie': categorie,
        'couleur': couleur,
        'stock': stock,
        'estActive': estActive,
        'imageAsset': imageAsset,
        'reference': reference,
      };
}
