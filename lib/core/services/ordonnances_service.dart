import '../api/api_client.dart';
import '../api/api_config.dart';

/// Service pour les ordonnances — upload, OCR, validation.
class OrdonnancesService {
  /// GET /api/ordonnances/ — Liste des ordonnances de l'utilisateur.
  static Future<ApiResult<List<dynamic>>> lister() async {
    return ApiClient.getList(ApiConfig.ordonnances);
  }

  /// POST /api/ordonnances/scanner/ — Envoie une image, le backend OCR
  /// extrait les valeurs optiques et crée l'ordonnance.
  static Future<ApiResult<Map<String, dynamic>>> scanner({
    required String imagePath,
  }) async {
    return ApiClient.uploadFile(
      ApiConfig.scannerOrdonnance,
      fieldName: 'image',
      filePath: imagePath,
    );
  }

  /// POST /api/ordonnances/ajouter/ — Ajouter une ordonnance manuellement.
  static Future<ApiResult<Map<String, dynamic>>> ajouter({
    required String imagePath,
  }) async {
    return ApiClient.uploadFile(
      ApiConfig.ajouterOrdonnance,
      fieldName: 'image',
      filePath: imagePath,
    );
  }

  /// GET /api/ordonnances/[id]/ — Détail d'une ordonnance.
  static Future<ApiResult<Map<String, dynamic>>> detail(int id) async {
    return ApiClient.get(ApiConfig.ordonnanceDetail(id));
  }

  /// POST /api/ordonnances/[id]/valider/ — Opticien valide l'ordonnance.
  static Future<ApiResult<Map<String, dynamic>>> valider(int id) async {
    return ApiClient.post(ApiConfig.validerOrdonnance(id));
  }
}
