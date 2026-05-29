import '../api/api_client.dart';
import '../api/api_config.dart';

/// Service d'authentification — login, inscription, profil.
class AuthService {
  /// POST /api/users/login/
  /// Retourne {token, refresh, user} ou une erreur.
  static Future<ApiResult<Map<String, dynamic>>> login({
    required String username,
    required String password,
  }) async {
    final result = await ApiClient.post(
      ApiConfig.login,
      body: {'username': username, 'password': password},
      withAuth: false,
    );

    if (result.isSuccess && result.data != null) {
      final token = result.data!['token'] as String?;
      final refresh = result.data!['refresh'] as String?;
      if (token != null && refresh != null) {
        await ApiClient.setTokens(access: token, refresh: refresh);
      }
    }
    return result;
  }

  /// POST /api/users/register/
  static Future<ApiResult<Map<String, dynamic>>> register({
    required String username,
    required String email,
    required String password,
    String role = 'client',
    String telephone = '',
    String adresse = '',
  }) async {
    return ApiClient.post(
      ApiConfig.register,
      body: {
        'username': username,
        'email': email,
        'password': password,
        'role': role,
        'telephone': telephone,
        'adresse': adresse,
      },
      withAuth: false,
    );
  }

  /// GET /api/users/profil/
  static Future<ApiResult<Map<String, dynamic>>> getProfil() async {
    return ApiClient.get(ApiConfig.profil);
  }

  /// PUT /api/users/profil/
  static Future<ApiResult<Map<String, dynamic>>> updateProfil({
    required Map<String, dynamic> data,
  }) async {
    return ApiClient.put(ApiConfig.profil, body: data);
  }

  /// Déconnexion locale (suppression des tokens).
  static Future<void> logout() async {
    await ApiClient.clearTokens();
  }
}
