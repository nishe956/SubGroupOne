import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class OcrService {
  final ApiClient apiClient;

  OcrService(this.apiClient);

  /// Récupère l'historique des ordonnances de l'utilisateur.
  Future<List<dynamic>> getUserPrescriptions() async {
    try {
      final response = await apiClient.get(ApiEndpoints.listPrescriptions);
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

final ocrServiceProvider = Provider<OcrService>((ref) {
  final client = ref.watch(apiClientProvider);
  return OcrService(client);
});
