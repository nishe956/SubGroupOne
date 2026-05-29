import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/commandes_service.dart';
import '../data/opticien_data.dart';
import '../models/commande_opticien.dart';

class CommandesOpticienNotifier extends StateNotifier<List<CommandeOpticien>> {
  CommandesOpticienNotifier() : super([]);

  /// Charge les commandes depuis l'API, avec fallback mock.
  Future<void> load() async {
    try {
      final result = await CommandesService.lister();

      if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
        final commandes = result.data!.map((json) {
          final j = json as Map<String, dynamic>;
          return CommandeOpticien(
            id: j['id'].toString(),
            nomClient: j['client_nom'] as String? ?? 'Client',
            contactClient: '',
            nomMonture: (j['monture_detail'] as Map<String, dynamic>?)?['nom']
                    as String? ??
                'Monture',
            imageMonture: '',
            prixMonture:
                (j['prix_total'] is String)
                    ? double.tryParse(j['prix_total'] as String) ?? 0
                    : (j['prix_total'] as num?)?.toDouble() ?? 0,
            statut: _parseStatut(j['statut'] as String? ?? 'en_attente'),
            dateCommande: DateTime.tryParse(
                    j['date_commande'] as String? ?? '') ??
                DateTime.now(),
            ordonnance: OrdonnanceDetail(imageAsset: ''),
            assurance: (j['nom_assurance'] as String?)?.isNotEmpty == true
                ? AssuranceDetail(
                    nomAssureur: j['nom_assurance'] as String? ?? '',
                    numeroPriseEnCharge:
                        j['numero_assurance'] as String? ?? '',
                    tauxRemboursement: 0,
                  )
                : null,
          );
        }).toList();

        state = commandes;
        return;
      }
    } catch (_) {
      // Fallback mock
    }

    // Fallback : données locales
    state = List.from(kMockCommandes);
  }

  /// Met à jour le statut d'une commande via l'API.
  Future<void> updateCommande(CommandeOpticien commande) async {
    final backendId = int.tryParse(commande.id);

    if (backendId != null) {
      try {
        final statutBackend = _statutToBackend(commande.statut);
        await CommandesService.gerer(
          id: backendId,
          statut: statutBackend,
          notes: commande.commentaireRejet,
        );
      } catch (_) {
        // Mise à jour locale même en cas d'échec réseau
      }
    }

    // Mise à jour locale
    state = state.map((c) => c.id == commande.id ? commande : c).toList();
  }

  static StatutCommande _parseStatut(String s) {
    switch (s) {
      case 'validee':
        return StatutCommande.validee;
      case 'rejetee':
        return StatutCommande.rejetee;
      case 'en_preparation':
      case 'livree':
        return StatutCommande.validee;
      default:
        return StatutCommande.enAttente;
    }
  }

  static String _statutToBackend(StatutCommande s) {
    switch (s) {
      case StatutCommande.validee:
        return 'validee';
      case StatutCommande.rejetee:
        return 'rejetee';
      case StatutCommande.enAttente:
        return 'en_attente';
    }
  }
}

final commandesOpticienProvider =
    StateNotifierProvider<CommandesOpticienNotifier, List<CommandeOpticien>>((ref) {
  return CommandesOpticienNotifier();
});
