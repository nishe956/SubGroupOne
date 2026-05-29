import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../models/commande_opticien.dart';
import '../providers/commandes_opticien_provider.dart';
import '../widgets/opticien_widgets.dart';
import 'detail_commande_screen.dart';

class GestionCommandesScreen extends ConsumerStatefulWidget {
  const GestionCommandesScreen({super.key});

  @override
  ConsumerState<GestionCommandesScreen> createState() => _GestionCommandesScreenState();
}

class _GestionCommandesScreenState extends ConsumerState<GestionCommandesScreen> {
  StatutCommande? _filtreStatut;

  List<CommandeOpticien> _filtrees(List<CommandeOpticien> all) {
    if (_filtreStatut == null) return all;
    return all.where((c) => c.statut == _filtreStatut).toList();
  }

  int _countByStatut(List<CommandeOpticien> all, StatutCommande s) =>
      all.where((c) => c.statut == s).length;

  @override
  Widget build(BuildContext context) {
    final commandes = ref.watch(commandesOpticienProvider);
    final liste = _filtrees(commandes);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: () =>
                ref.read(commandesOpticienProvider.notifier).load(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _Chip(label: 'Toutes', count: commandes.length,
                    statut: null, selected: _filtreStatut == null,
                    onTap: () => setState(() => _filtreStatut = null)),
                const SizedBox(width: 8),
                _Chip(label: 'En attente', count: _countByStatut(commandes, StatutCommande.enAttente),
                    statut: StatutCommande.enAttente, selected: _filtreStatut == StatutCommande.enAttente,
                    onTap: () => setState(() => _filtreStatut =
                        _filtreStatut == StatutCommande.enAttente ? null : StatutCommande.enAttente)),
                const SizedBox(width: 8),
                _Chip(label: 'Validées', count: _countByStatut(commandes, StatutCommande.validee),
                    statut: StatutCommande.validee, selected: _filtreStatut == StatutCommande.validee,
                    onTap: () => setState(() => _filtreStatut =
                        _filtreStatut == StatutCommande.validee ? null : StatutCommande.validee)),
                const SizedBox(width: 8),
                _Chip(label: 'Rejetées', count: _countByStatut(commandes, StatutCommande.rejetee),
                    statut: StatutCommande.rejetee, selected: _filtreStatut == StatutCommande.rejetee,
                    onTap: () => setState(() => _filtreStatut =
                        _filtreStatut == StatutCommande.rejetee ? null : StatutCommande.rejetee)),
              ],
            ),
          ),
          Expanded(
            child: liste.isEmpty
                ? EstherErrorWidget(
                    message: _filtreStatut != null
                        ? 'Aucune commande avec ce statut.'
                        : 'Aucune commande pour le moment.',
                    onRetry: () => setState(() {}),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: liste.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = liste[i];
                      return CommandeCard(
                        nomClient: c.nomClient,
                        nomMonture: c.nomMonture,
                        dateCommande: c.dateCommande,
                        prixMonture: c.prixMonture,
                        statut: c.statut,
                        onTap: () async {
                          final updated = await Navigator.of(context).push<CommandeOpticien>(
                            MaterialPageRoute(builder: (_) => DetailCommandeScreen(commande: c)),
                          );
                          if (updated != null) {
                            ref.read(commandesOpticienProvider.notifier).updateCommande(updated);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label, required this.count, required this.statut,
    required this.selected, required this.onTap,
  });
  final String label;
  final int count;
  final StatutCommande? statut;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text('$label ($count)'),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.brownMedium,
      backgroundColor: AppColors.cream,
      checkmarkColor: AppColors.cream,
      labelStyle: TextStyle(
          color: selected ? AppColors.cream : AppColors.brownDark,
          fontWeight: FontWeight.w600),
      side: BorderSide(
          color: selected ? AppColors.brownMedium : AppColors.brownLight.withValues(alpha: 0.5)),
    );
  }
}
