import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/montures_service.dart';
import '../data/opticien_data.dart';
import '../models/monture_opticien.dart';

class MonturesOpticienNotifier extends StateNotifier<List<MontureOpticien>> {
  MonturesOpticienNotifier() : super([]);

  /// Charge les montures depuis l'API, avec fallback mock.
  Future<void> load() async {
    try {
      final result = await MonturesService.lister();

      if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
        final montures = result.data!.map((json) {
          final j = json as Map<String, dynamic>;
          return MontureOpticien(
            id: j['id'].toString(),
            nom: j['nom'] as String? ?? '',
            marque: j['marque'] as String? ?? '',
            prix: (j['prix'] is String)
                ? double.tryParse(j['prix'] as String) ?? 0
                : (j['prix'] as num?)?.toDouble() ?? 0,
            description: j['description'] as String? ?? '',
            categorie: j['forme_display'] as String? ?? j['forme'] as String? ?? '',
            couleur: j['couleur'] as String? ?? '',
            stock: j['stock'] as int? ?? 0,
            estActive: j['disponible'] as bool? ?? true,
            imageAsset: j['image'] as String?,
            reference: j['reference'] as String?,
          );
        }).toList();

        state = montures;
        return;
      }
    } catch (_) {
      // Fallback mock
    }

    // Fallback : données locales
    state = List.from(kMockMontures);
  }

  /// Ajoute ou modifie une monture (API + local).
  Future<void> addOrUpdate(MontureOpticien monture) async {
    final backendId = int.tryParse(monture.id);

    try {
      final apiData = {
        'nom': monture.nom,
        'marque': monture.marque,
        'prix': monture.prix,
        'forme': _categorieToForme(monture.categorie),
        'couleur': monture.couleur,
        'reference': monture.reference ?? '',
        'description': monture.description,
        'stock': monture.stock,
        'disponible': monture.estActive,
      };

      if (backendId != null) {
        // Tentative de mise à jour backend
        await MonturesService.modifier(id: backendId, data: apiData);
      } else {
        // Tentative de création backend
        await MonturesService.creer(data: apiData);
      }
    } catch (_) {
      // Mise à jour locale même en cas d'échec
    }

    // Mise à jour locale
    final idx = state.indexWhere((m) => m.id == monture.id);
    if (idx >= 0) {
      final newState = List<MontureOpticien>.from(state);
      newState[idx] = monture;
      state = newState;
    } else {
      state = [...state, monture];
    }
  }

  /// Active/désactive une monture.
  Future<void> toggleActive(String id) async {
    final backendId = int.tryParse(id);
    final monture = state.firstWhere((m) => m.id == id);
    final newActive = !monture.estActive;

    if (backendId != null) {
      try {
        await MonturesService.modifier(
          id: backendId,
          data: {'disponible': newActive},
        );
      } catch (_) {}
    }

    state = state.map((m) {
      if (m.id == id) {
        return m.copyWith(estActive: newActive);
      }
      return m;
    }).toList();
  }

  /// Supprime une monture.
  Future<void> delete(String id) async {
    final backendId = int.tryParse(id);

    if (backendId != null) {
      try {
        await MonturesService.supprimer(backendId);
      } catch (_) {}
    }

    state = state.where((m) => m.id != id).toList();
  }

  /// Convertit une catégorie display en clé backend.
  static String _categorieToForme(String categorie) {
    const mapping = {
      'Lunettes de vue': 'lunettes_de_vue',
      'Lunettes de soleil': 'lunettes_de_soleil',
      'Anti-lumière bleue': 'anti_lumiere_bleue',
      'Rondes': 'ronde',
      'Rectangulaires': 'rectangulaire',
      'Carrées': 'carree',
      'Œil de chat (ou Cat-eye)': 'oeil_de_chat',
      'Aviateur': 'aviateur',
      'Oversize': 'oversize',
      'Ovale': 'ovale',
    };
    return mapping[categorie] ?? 'ronde';
  }
}

final monturesOpticienProvider =
    StateNotifierProvider<MonturesOpticienNotifier, List<MontureOpticien>>((ref) {
  return MonturesOpticienNotifier();
});
