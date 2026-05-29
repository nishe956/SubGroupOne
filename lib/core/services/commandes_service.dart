import '../api/api_client.dart';
import '../api/api_config.dart';

/// Service pour les commandes.
class CommandesService {
  /// GET /api/commandes/ — Liste des commandes.
  static Future<ApiResult<List<dynamic>>> lister() async {
    return ApiClient.getList(ApiConfig.commandes);
  }

  /// POST /api/commandes/passer/ — Passer une nouvelle commande.
  static Future<ApiResult<Map<String, dynamic>>> passer({
    required int montureId,
    int? ordonnanceId,
    String? numeroAssurance,
    String? nomAssurance,
  }) async {
    final body = <String, dynamic>{
      'monture': montureId,
    };
    if (ordonnanceId != null) body['ordonnance'] = ordonnanceId;
    if (numeroAssurance != null) body['numero_assurance'] = numeroAssurance;
    if (nomAssurance != null) body['nom_assurance'] = nomAssurance;

    return ApiClient.post(ApiConfig.passerCommande, body: body);
  }

  /// GET /api/commandes/[id]/ — Détail d'une commande.
  static Future<ApiResult<Map<String, dynamic>>> detail(int id) async {
    return ApiClient.get(ApiConfig.commandeDetail(id));
  }

  /// POST /api/commandes/[id]/gerer/ — Modifier le statut (opticien/admin).
  static Future<ApiResult<Map<String, dynamic>>> gerer({
    required int id,
    required String statut,
    String? notes,
  }) async {
    final body = <String, dynamic>{'statut': statut};
    if (notes != null) body['notes'] = notes;

    return ApiClient.post(ApiConfig.gererCommande(id), body: body);
  }
}
