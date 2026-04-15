import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class User {
  final int id;
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;

  User({
    required this.id,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: json['role'] ?? 'client',
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }
}

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      state = state.copyWith(user: User.fromJson(jsonDecode(userJson)));
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        await prefs.setString('refresh_token', data['refresh']);
        
        // Fetch profile to get user details
        final profileResponse = await apiClient.get(ApiEndpoints.profile);
        final user = User.fromJson(profileResponse.data);
        
        await prefs.setString('user_data', jsonEncode(profileResponse.data));
        state = state.copyWith(user: user, isLoading: false);
        return true;
      }
    } on DioException catch (e) {
      String message = "Erreur de connexion. Vérifiez vos identifiants.";
      if (e.response?.data is Map) {
        message = (e.response?.data as Map).values.first.toString();
      } else if (e.message != null) {
        message = "Erreur réseau: ${e.message}";
      }
      state = state.copyWith(isLoading: false, error: message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Une erreur inattendue est survenue: $e");
    }

    return false;
  }

  Future<bool> register(String email, String password, String firstName, String lastName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.post(ApiEndpoints.register, data: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      });

      if (response.statusCode == 201) {
        state = state.copyWith(isLoading: false);
        return true;
      }
    } on DioException catch (e) {
      String message = "Erreur lors de l'inscription.";
      if (e.response?.data is Map) {
        message = (e.response?.data as Map).values.first.toString();
      } else if (e.message != null) {
        message = "Erreur réseau: ${e.message}";
      }
      state = state.copyWith(isLoading: false, error: message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Une erreur inattendue est survenue: $e");
    }

    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
