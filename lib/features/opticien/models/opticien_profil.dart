/// Profil complet d'un opticien connecté.
class OpticienProfil {
  const OpticienProfil({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.boutique,
    required this.email,
    required this.telephone,
    required this.adresse,
  });

  final String id;
  final String prenom;
  final String nom;
  final String boutique;
  final String email;
  final String telephone;
  final String adresse;

  String get nomComplet => '$prenom $nom';

  OpticienProfil copyWith({
    String? prenom,
    String? nom,
    String? boutique,
    String? email,
    String? telephone,
    String? adresse,
  }) {
    return OpticienProfil(
      id: id,
      prenom: prenom ?? this.prenom,
      nom: nom ?? this.nom,
      boutique: boutique ?? this.boutique,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
    );
  }

  factory OpticienProfil.fromJson(Map<String, dynamic> json) {
    return OpticienProfil(
      id: json['id'] as String,
      prenom: json['prenom'] as String,
      nom: json['nom'] as String,
      boutique: json['boutique'] as String,
      email: json['email'] as String,
      telephone: json['telephone'] as String,
      adresse: json['adresse'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'prenom': prenom,
        'nom': nom,
        'boutique': boutique,
        'email': email,
        'telephone': telephone,
        'adresse': adresse,
      };
}
