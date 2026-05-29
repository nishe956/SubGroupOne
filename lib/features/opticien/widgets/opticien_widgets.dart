import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../models/commande_opticien.dart';

/// Badge coloré affichant le statut d'une commande.
/// Réutilisable dans toutes les listes et fiches de commande.
class StatutBadge extends StatelessWidget {
  const StatutBadge({
    super.key,
    required this.statut,
    this.compact = false,
  });

  final StatutCommande statut;

  /// Si [compact] = true, affiche uniquement l'icône (sans libellé texte).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: statut.backgroundColor,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(
          color: statut.color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statut.icon, size: 14, color: statut.color),
          if (!compact) ...[
            const SizedBox(width: 5),
            Text(
              statut.label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: statut.color,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Carte de commande utilisée dans [GestionCommandesScreen].
class CommandeCard extends StatelessWidget {
  const CommandeCard({
    super.key,
    required this.nomClient,
    required this.nomMonture,
    required this.dateCommande,
    required this.prixMonture,
    required this.statut,
    required this.onTap,
  });

  final String nomClient;
  final String nomMonture;
  final DateTime dateCommande;
  final double prixMonture;
  final StatutCommande statut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${dateCommande.day.toString().padLeft(2, '0')}/'
        '${dateCommande.month.toString().padLeft(2, '0')}/'
        '${dateCommande.year}  '
        '${dateCommande.hour.toString().padLeft(2, '0')}h'
        '${dateCommande.minute.toString().padLeft(2, '0')}';

    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.brownLight.withValues(alpha: 0.18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.brownLight.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              // Avatar client
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.nude,
                child: Text(
                  nomClient.isNotEmpty ? nomClient[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.brownMedium,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Infos commande
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomClient,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.brownDark,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nomMonture,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.brownDark.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.brownMedium.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Prix + badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${prixMonture.toStringAsFixed(0)} €',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.brownMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StatutBadge(statut: statut),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.brownLight.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte de monture utilisée dans [GestionMonturesScreen].
class MontureCard extends StatelessWidget {
  const MontureCard({
    super.key,
    required this.nom,
    required this.marque,
    required this.prix,
    required this.stock,
    required this.estActive,
    required this.imageAsset,
    required this.onToggleActive,
    required this.onModifier,
    required this.onSupprimer,
  });

  final String nom;
  final String marque;
  final double prix;
  final int stock;
  final bool estActive;
  final String? imageAsset;
  final VoidCallback onToggleActive;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.brownLight.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          // Image de la monture
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
            child: SizedBox(
              width: 90,
              height: 90,
              child: imageAsset != null
                  ? Image.asset(
                      imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                    )
                  : const _ImagePlaceholder(),
            ),
          ),
          const SizedBox(width: 14),

          // Infos
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: AppColors.brownDark,
                          ),
                        ),
                      ),
                      // Badge actif / inactif
                      _ActiveBadge(estActive: estActive),
                      const SizedBox(width: 10),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    marque,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.brownMedium.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${prix.toStringAsFixed(0)} €',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.brownMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        stock > 0
                            ? Icons.inventory_2_outlined
                            : Icons.remove_shopping_cart_outlined,
                        size: 14,
                        color: stock > 0
                            ? AppColors.brownDark.withValues(alpha: 0.6)
                            : const Color(0xFF8B3A3A),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        stock > 0 ? 'Stock : $stock' : 'Rupture',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: stock > 0
                              ? AppColors.brownDark.withValues(alpha: 0.6)
                              : const Color(0xFF8B3A3A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Menu contextuel
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: AppColors.brownDark.withValues(alpha: 0.6),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: AppColors.cream,
            onSelected: (value) {
              switch (value) {
                case 'modifier':
                  onModifier();
                case 'toggle':
                  onToggleActive();
                case 'supprimer':
                  onSupprimer();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'modifier',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 10),
                  Text('Modifier'),
                ]),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(children: [
                  Icon(
                    estActive
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(estActive ? 'Désactiver' : 'Activer'),
                ]),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'supprimer',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 18, color: Color(0xFF8B3A3A)),
                  SizedBox(width: 10),
                  Text('Supprimer',
                      style: TextStyle(color: Color(0xFF8B3A3A))),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.estActive});

  final bool estActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: estActive
            ? const Color(0xFFD4EDDA)
            : AppColors.nude.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        estActive ? 'Actif' : 'Inactif',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: estActive
              ? const Color(0xFF4A7C59)
              : AppColors.brownDark.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.nude,
      child: Icon(
        Icons.remove_red_eye_outlined,
        size: 32,
        color: AppColors.brownMedium.withValues(alpha: 0.4),
      ),
    );
  }
}

/// Widget générique affichant un champ d'information sous forme de ligne.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.valeur,
    this.icone,
  });

  final String label;
  final String valeur;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icone != null) ...[
            Icon(icone!, size: 18, color: AppColors.brownMedium),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.brownDark.withValues(alpha: 0.65),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              valeur.isEmpty ? '—' : valeur,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.brownDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading indicator centré et stylisé.
class EstherLoadingIndicator extends StatelessWidget {
  const EstherLoadingIndicator({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.brownMedium,
            strokeWidth: 2.5,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: AppColors.brownDark.withValues(alpha: 0.65),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget d'erreur générique avec bouton "Réessayer".
class EstherErrorWidget extends StatelessWidget {
  const EstherErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.brownMedium.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.brownDark.withValues(alpha: 0.75),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
