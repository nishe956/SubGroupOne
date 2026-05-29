import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_config.dart';

/// Service pour l'essai virtuel (envoi photo → backend face_detection).
class EssaiService {
  /// POST /api/essai/essayer/
  /// Envoie une image base64 + couleur, reçoit l'image avec monture.
  static Future<ApiResult<Map<String, dynamic>>> essayer({
    required String imageBase64,
    String couleur = 'noir',
  }) async {
    return ApiClient.post(
      ApiConfig.essayerMonture,
      body: {
        'image': imageBase64,
        'couleur': couleur,
      },
    );
  }

  /// Convertit les bytes d'une capture caméra en base64.
  static String bytesToBase64(List<int> bytes) {
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }
}
