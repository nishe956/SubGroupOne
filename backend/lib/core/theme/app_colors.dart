import 'package:flutter/material.dart';

abstract final class AppColors {
  /// Beige crème — fond principal / surfaces claires
  static const Color cream = Color(0xFFF4EFEA);
  
  /// Nude / sable — cartes, éléments secondaires
  static const Color nude = Color(0xFFD9C5B2);
  
  /// Brun clair — accents doux, boutons secondaires
  static const Color brownLight = Color(0xFFB89A7A);
  
  /// Brun moyen — accents principaux, textes importants
  static const Color brownMedium = Color(0xFF8A6B4F);
  
  /// Brun foncé — textes sombres, barres, icônes
  static const Color brownDark = Color(0xFF4A3A2A);

  // Maintain compatibility with old names if needed, but we'll transition.
  static const Color beigeCreme = cream;
  static const Color nudeSable = nude;
  static const Color brunClair = brownLight;
  static const Color brunMoyen = brownMedium;
  static const Color brunFonce = brownDark;
  
  static const Color orDoux = Color(0xFFC8A97E);
  static const Color noirDoux = Color(0xFF1E1E1E);
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF388E3C);
}
