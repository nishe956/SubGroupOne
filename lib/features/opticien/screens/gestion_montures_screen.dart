import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../models/monture_opticien.dart';
import '../providers/montures_opticien_provider.dart';
import '../widgets/opticien_widgets.dart';
import 'ajouter_modifier_monture_screen.dart';

class GestionMonturesScreen extends ConsumerStatefulWidget {
  const GestionMonturesScreen({super.key});

  @override
  ConsumerState<GestionMonturesScreen> createState() => _GestionMonturesScreenState();
}

class _GestionMonturesScreenState extends ConsumerState<GestionMonturesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MontureOpticien> _filtrees(List<MontureOpticien> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((m) =>
        m.nom.toLowerCase().contains(q) ||
        m.marque.toLowerCase().contains(q) ||
        (m.reference?.toLowerCase().contains(q) ?? false)).toList();
  }

  void _supprimer(MontureOpticien monture) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.cream,
        title: const Text('Supprimer la monture'),
        content: Text('Voulez-vous vraiment supprimer « ${monture.nom} » ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B3A3A)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirme == true) {
      ref.read(monturesOpticienProvider.notifier).delete(monture.id);
    }
  }

  void _ouvrir({MontureOpticien? monture}) async {
    final result = await Navigator.of(context).push<MontureOpticien>(
      MaterialPageRoute(builder: (_) => AjouterModifierMontureScreen(monture: monture)),
    );
    if (result != null) {
      ref.read(monturesOpticienProvider.notifier).addOrUpdate(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final montures = ref.watch(monturesOpticienProvider);
    final liste = _filtrees(montures);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes montures'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('${liste.length} article(s)',
                style: TextStyle(fontSize: 12.5,
                    color: AppColors.brownDark.withValues(alpha: 0.55))),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, marque, référence…',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.brownMedium),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: liste.isEmpty
                ? EstherErrorWidget(
                    message: _query.isNotEmpty
                        ? 'Aucune monture ne correspond à votre recherche.'
                        : 'Votre catalogue est vide.\nAjoutez votre première monture !',
                    onRetry: _query.isNotEmpty ? null : () => setState(() {}),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: liste.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final m = liste[i];
                      return MontureCard(
                        nom: m.nom,
                        marque: m.marque,
                        prix: m.prix,
                        stock: m.stock,
                        estActive: m.estActive,
                        imageAsset: m.imageAsset,
                        onToggleActive: () => ref.read(monturesOpticienProvider.notifier).toggleActive(m.id),
                        onModifier: () => _ouvrir(monture: m),
                        onSupprimer: () => _supprimer(m),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ouvrir(),
        backgroundColor: AppColors.brownMedium,
        foregroundColor: AppColors.cream,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
