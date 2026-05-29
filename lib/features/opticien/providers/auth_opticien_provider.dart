import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../data/opticien_data.dart';
import '../models/opticien_profil.dart';
import 'commandes_opticien_provider.dart';
import 'montures_opticien_provider.dart';

class AuthOpticienNotifier extends StateNotifier<OpticienProfil?> {
  AuthOpticienNotifier(this.ref) : super(null);

  final Ref ref;

  /// Connexion opticien via l'API backend.
  /// Fallback sur les identifiants démo si le backend n'est pas disponible.
  Future<bool> login(String email, String password) async {
    // ── Tentative de connexion via le backend ──
    try {
      // Le backend utilise 'username' ; on extrait le nom d'utilisateur de l'email
      final username = email.contains('@') ? email.split('@').first : email;

      final result = await AuthService.login(
        username: username,
        password: password,
      );

      if (result.isSuccess && result.data != null) {
        final userData = result.data!['user'] as Map<String, dynamic>?;
        if (userData != null) {
          final role = userData['role'] as String? ?? '';
          if (role == 'opticien' || role == 'admin') {
            state = OpticienProfil(
              id: userData['id'].toString(),
              prenom: (userData['username'] as String? ?? '').split(' ').first,
              nom: (userData['username'] as String? ?? '').split(' ').length > 1
                  ? (userData['username'] as String).split(' ').sublist(1).join(' ')
                  : '',
              boutique: 'Optique Esther',
              email: userData['email'] as String? ?? email,
              telephone: userData['telephone'] as String? ?? '',
              adresse: userData['adresse'] as String? ?? '',
            );

            // Charger les données depuis l'API
            ref.read(commandesOpticienProvider.notifier).load();
            ref.read(monturesOpticienProvider.notifier).load();
            return true;
          }
        }
      }
    } catch (_) {
      // Backend indisponible → fallback démo
    }

    // ── Fallback : identifiants de démonstration ──
    await Future<void>.delayed(const Duration(seconds: 1));

    if (email == 'opticien@esther.fr' && password == 'esther2025') {
      state = kDemoOpticien;
      ref.read(commandesOpticienProvider.notifier).load();
      ref.read(monturesOpticienProvider.notifier).load();
      return true;
    }
    return false;
  }

  void logout() {
    ApiClient.clearTokens();
    state = null;
  }

  void updateProfil(OpticienProfil profil) {
    state = profil;
  }
}

final authOpticienProvider =
    StateNotifierProvider<AuthOpticienNotifier, OpticienProfil?>((ref) {
  return AuthOpticienNotifier(ref);
});
