import '../api/api_client.dart';
import '../api/api_config.dart';

/// Service pour les montures — CRUD + filtres.
class MonturesService {
  /// GET /api/montures/ — Liste avec filtres optionnels.
  static Future<ApiResult<List<dynamic>>> lister({
    String? forme,
    String? couleur,
    String? marque,
  }) async {
    final params = <String, String>{};
    if (forme != null) params['forme'] = forme;
    if (couleur != null) params['couleur'] = couleur;
    if (marque != null) params['marque'] = marque;

    return ApiClient.getList(
      ApiConfig.montures,
      queryParams: params.isEmpty ? null : params,
      withAuth: false, // GET est public
    );
  }

  /// GET /api/montures/[id]/ — Détail d'une monture.
  static Future<ApiResult<Map<String, dynamic>>> detail(int id) async {
    return ApiClient.get(
      ApiConfig.montureDetail(id),
      withAuth: false,
    );
  }

  /// POST /api/montures/ — Créer une monture (opticien/admin).
  static Future<ApiResult<Map<String, dynamic>>> creer({
    required Map<String, dynamic> data,
  }) async {
    return ApiClient.post(ApiConfig.montures, body: data);
  }

  /// PUT /api/montures/[id]/ — Modifier une monture.
  static Future<ApiResult<Map<String, dynamic>>> modifier({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    return ApiClient.put(ApiConfig.montureDetail(id), body: data);
  }

  /// DELETE /api/montures/[id]/ — Supprimer une monture.
  static Future<ApiResult<Map<String, dynamic>>> supprimer(int id) async {
    return ApiClient.delete(ApiConfig.montureDetail(id));
  }
}
