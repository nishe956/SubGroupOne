import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

/// Résultat générique d'un appel API.
class ApiResult<T> {
  final T? data;
  final String? error;
  final int statusCode;

  const ApiResult({this.data, this.error, required this.statusCode});

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// Client HTTP centralisé avec gestion du JWT.
class ApiClient {
  // ── Gestion du token ─────────────────────────────────────────────────

  static String? _token;
  static String? _refreshToken;

  static Future<void> setTokens({
    required String access,
    required String refresh,
  }) async {
    _token = access;
    _refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  static Future<String?> getRefreshToken() async {
    if (_refreshToken != null) return _refreshToken;
    final prefs = await SharedPreferences.getInstance();
    _refreshToken = prefs.getString('refresh_token');
    return _refreshToken;
  }

  static Future<void> clearTokens() async {
    _token = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Headers ──────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = await getToken();
      if (token != null) {
        h['Authorization'] = 'Bearer $token';
      }
    }
    return h;
  }

  // ── Méthodes HTTP ────────────────────────────────────────────────────

  static Uri _uri(String path, [Map<String, String>? queryParams]) {
    final base = Uri.parse('${ApiConfig.baseUrl}$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return base.replace(queryParameters: queryParams);
    }
    return base;
  }

  /// GET request.
  static Future<ApiResult<Map<String, dynamic>>> get(
    String path, {
    Map<String, String>? queryParams,
    bool withAuth = true,
  }) async {
    try {
      final response = await http.get(
        _uri(path, queryParams),
        headers: await _headers(withAuth: withAuth),
      );
      return _parseResponse(response);
    } catch (e) {
      return ApiResult(
        error: 'Erreur réseau : $e',
        statusCode: 0,
      );
    }
  }

  /// GET request retournant une liste.
  static Future<ApiResult<List<dynamic>>> getList(
    String path, {
    Map<String, String>? queryParams,
    bool withAuth = true,
  }) async {
    try {
      final response = await http.get(
        _uri(path, queryParams),
        headers: await _headers(withAuth: withAuth),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          return ApiResult(data: decoded, statusCode: response.statusCode);
        }
        // Si le backend pagine, extraire les résultats
        if (decoded is Map && decoded.containsKey('results')) {
          return ApiResult(
            data: decoded['results'] as List,
            statusCode: response.statusCode,
          );
        }
        return ApiResult(data: [decoded], statusCode: response.statusCode);
      }
      return ApiResult(
        error: _extractError(response),
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResult(error: 'Erreur réseau : $e', statusCode: 0);
    }
  }

  /// POST request.
  static Future<ApiResult<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    try {
      final response = await http.post(
        _uri(path),
        headers: await _headers(withAuth: withAuth),
        body: body != null ? jsonEncode(body) : null,
      );
      return _parseResponse(response);
    } catch (e) {
      return ApiResult(error: 'Erreur réseau : $e', statusCode: 0);
    }
  }

  /// PUT request.
  static Future<ApiResult<Map<String, dynamic>>> put(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    try {
      final response = await http.put(
        _uri(path),
        headers: await _headers(withAuth: withAuth),
        body: body != null ? jsonEncode(body) : null,
      );
      return _parseResponse(response);
    } catch (e) {
      return ApiResult(error: 'Erreur réseau : $e', statusCode: 0);
    }
  }

  /// PATCH request.
  static Future<ApiResult<Map<String, dynamic>>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    try {
      final response = await http.patch(
        _uri(path),
        headers: await _headers(withAuth: withAuth),
        body: body != null ? jsonEncode(body) : null,
      );
      return _parseResponse(response);
    } catch (e) {
      return ApiResult(error: 'Erreur réseau : $e', statusCode: 0);
    }
  }

  /// DELETE request.
  static Future<ApiResult<Map<String, dynamic>>> delete(
    String path, {
    bool withAuth = true,
  }) async {
    try {
      final response = await http.delete(
        _uri(path),
        headers: await _headers(withAuth: withAuth),
      );
      if (response.statusCode == 204) {
        return const ApiResult(data: {}, statusCode: 204);
      }
      return _parseResponse(response);
    } catch (e) {
      return ApiResult(error: 'Erreur réseau : $e', statusCode: 0);
    }
  }

  /// Upload multipart (pour images d'ordonnances, montures, etc.).
  static Future<ApiResult<Map<String, dynamic>>> uploadFile(
    String path, {
    required String fieldName,
    required String filePath,
    Map<String, String>? extraFields,
    bool withAuth = true,
  }) async {
    try {
      final request = http.MultipartRequest('POST', _uri(path));
      final token = await getToken();
      if (withAuth && token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
      if (extraFields != null) {
        request.fields.addAll(extraFields);
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return _parseResponse(response);
    } catch (e) {
      return ApiResult(error: 'Erreur upload : $e', statusCode: 0);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  static ApiResult<Map<String, dynamic>> _parseResponse(
    http.Response response,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return ApiResult(data: const {}, statusCode: response.statusCode);
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return ApiResult(
        data: decoded is Map<String, dynamic> ? decoded : {'data': decoded},
        statusCode: response.statusCode,
      );
    }
    return ApiResult(
      error: _extractError(response),
      statusCode: response.statusCode,
    );
  }

  static String _extractError(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map) {
        // Django REST framework error formats
        if (body.containsKey('erreur')) return body['erreur'] as String;
        if (body.containsKey('detail')) return body['detail'] as String;
        if (body.containsKey('non_field_errors')) {
          return (body['non_field_errors'] as List).join(', ');
        }
        // Field-level errors
        final errors = <String>[];
        body.forEach((key, value) {
          if (value is List) {
            errors.add('$key: ${value.join(", ")}');
          } else {
            errors.add('$key: $value');
          }
        });
        if (errors.isNotEmpty) return errors.join('\n');
      }
      return 'Erreur ${response.statusCode}';
    } catch (_) {
      return 'Erreur ${response.statusCode}';
    }
  }
}
