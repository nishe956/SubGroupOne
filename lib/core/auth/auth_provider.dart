import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../services/auth_service.dart';

/// Modèle utilisateur connecté.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.telephone = '',
    this.adresse = '',
  });

  final int id;
  final String username;
  final String email;
  final String role;
  final String telephone;
  final String adresse;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'client',
      telephone: json['telephone'] as String? ?? '',
      adresse: json['adresse'] as String? ?? '',
    );
  }

  bool get isOpticien => role == 'opticien' || role == 'admin';
}

/// État d'authentification.
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  final AuthStatus status;
  final UserProfile? user;
  final String? error;

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

/// Notifier Riverpod pour l'authentification.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  /// Vérifie au lancement si un token est déjà stocké.
  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    final loggedIn = await ApiClient.isLoggedIn();
    if (loggedIn) {
      // Tenter de charger le profil
      final result = await AuthService.getProfil();
      if (result.isSuccess && result.data != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: UserProfile.fromJson(result.data!),
        );
        return;
      }
      // Token expiré
      await ApiClient.clearTokens();
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Connexion.
  Future<bool> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await AuthService.login(
      username: username,
      password: password,
    );

    if (result.isSuccess && result.data != null) {
      final userData = result.data!['user'] as Map<String, dynamic>?;
      if (userData != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: UserProfile.fromJson(userData),
        );
        return true;
      }
    }

    state = AuthState(
      status: AuthStatus.error,
      error: result.error ?? 'Identifiants incorrects',
    );
    return false;
  }

  /// Inscription.
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String role = 'client',
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await AuthService.register(
      username: username,
      email: email,
      password: password,
      role: role,
    );

    if (result.isSuccess) {
      // Auto-login après inscription
      return login(username, password);
    }

    state = AuthState(
      status: AuthStatus.error,
      error: result.error ?? 'Échec de l\'inscription',
    );
    return false;
  }

  /// Déconnexion.
  Future<void> logout() async {
    await AuthService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Passer en mode invité (accès catalogue uniquement).
  void continueAsGuest() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
