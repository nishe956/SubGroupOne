import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../models/commande_opticien.dart';
import '../providers/auth_opticien_provider.dart';
import '../providers/commandes_opticien_provider.dart';
import '../providers/montures_opticien_provider.dart';
import 'consultation_ordonnances_screen.dart';
import 'opticien_shell_screen.dart';

class OpticienDashboardScreen extends ConsumerWidget {
  const OpticienDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(authOpticienProvider);
    final commandes = ref.watch(commandesOpticienProvider);
    final montures = ref.watch(monturesOpticienProvider);

    if (profil == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    int countByStatut(StatutCommande s) =>
        commandes.where((c) => c.statut == s).length;

    final enAttente = countByStatut(StatutCommande.enAttente);
    final validees = countByStatut(StatutCommande.validee);
    final rejetees = countByStatut(StatutCommande.rejetee);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bonjour,',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.brownDark.withValues(alpha: 0.6))),
                          Text(
                            profil.prenom,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brownDark,
                                  letterSpacing: -0.3,
                                ),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.brownMedium,
                      child: Text(
                        profil.prenom.isNotEmpty ? profil.prenom[0].toUpperCase() : 'O',
                        style: const TextStyle(
                            color: AppColors.cream, fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.brownMedium, AppColors.brownDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded, color: AppColors.cream, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profil.boutique,
                                style: const TextStyle(
                                    color: AppColors.cream,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                            const SizedBox(height: 3),
                            Text(profil.adresse,
                                style: TextStyle(
                                    color: AppColors.cream.withValues(alpha: 0.75),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Text('Commandes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.brownDark)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _MetriqueCard(
                          label: 'En attente', valeur: enAttente,
                          couleur: const Color(0xFFB8860B),
                          couleurFond: const Color(0xFFFFF3CD),
                          icone: Icons.hourglass_empty_rounded),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetriqueCard(
                          label: 'Validées', valeur: validees,
                          couleur: const Color(0xFF4A7C59),
                          couleurFond: const Color(0xFFD4EDDA),
                          icone: Icons.check_circle_rounded),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetriqueCard(
                          label: 'Rejetées', valeur: rejetees,
                          couleur: const Color(0xFF8B3A3A),
                          couleurFond: const Color(0xFFF8D7DA),
                          icone: Icons.cancel_rounded),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                child: Text('Accès rapides',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.brownDark)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  children: [
                    _AccesRapideRow(
                      icone: Icons.remove_red_eye_rounded,
                      titre: 'Mes montures',
                      sousTitre: '${montures.length} article(s) au catalogue',
                      onTap: () => ref.read(opticienTabProvider.notifier).state = 1,
                    ),
                    const SizedBox(height: 10),
                    _AccesRapideRow(
                      icone: Icons.shopping_bag_rounded,
                      titre: 'Commandes en attente',
                      sousTitre: '$enAttente commande(s) à traiter',
                      badge: enAttente > 0 ? '$enAttente' : null,
                      onTap: () => ref.read(opticienTabProvider.notifier).state = 2,
                    ),
                    const SizedBox(height: 10),
                    _AccesRapideRow(
                      icone: Icons.document_scanner_outlined,
                      titre: 'Ordonnances',
                      sousTitre: 'Consulter les ordonnances scannées',
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => ConsultationOrdonnancesScreen(commandes: commandes),
                        ));
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _MetriqueCard extends StatelessWidget {
  const _MetriqueCard({
    required this.label, required this.valeur,
    required this.couleur, required this.couleurFond, required this.icone,
  });
  final String label;
  final int valeur;
  final Color couleur, couleurFond;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: couleurFond,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icone, color: couleur, size: 24),
          const SizedBox(height: 8),
          Text('$valeur',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                  color: couleur, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: couleur.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

class _AccesRapideRow extends StatelessWidget {
  const _AccesRapideRow({
    required this.icone, required this.titre, required this.sousTitre,
    required this.onTap, this.badge,
  });
  final IconData icone;
  final String titre, sousTitre;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.brownLight.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.nude, borderRadius: BorderRadius.circular(12)),
                child: Icon(icone, color: AppColors.brownMedium, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre, style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.brownDark)),
                    const SizedBox(height: 2),
                    Text(sousTitre, style: TextStyle(
                        fontSize: 12, color: AppColors.brownDark.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFB8860B).withValues(alpha: 0.4)),
                  ),
                  child: Text(badge!,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12,
                          color: Color(0xFFB8860B))),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: AppColors.brownLight.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
