import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../ar_providers.dart';

/// Barre de contrôle flottante (fermer, flash, capture, flip caméra).
class ArControlSheet extends ConsumerWidget {
  const ArControlSheet({
    super.key,
    required this.onClose,
    required this.onCapture,
  });

  final VoidCallback onClose;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flash = ref.watch(flashEnabledProvider);
    final front = ref.watch(useFrontCameraProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          color: AppColors.cream.withValues(alpha: 0.94),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircleIcon(
                tooltip: 'Fermer',
                icon: Icons.close_rounded,
                semanticLabel: 'Fermer l’essayage',
                onTap: onClose,
              ),
              _CircleIcon(
                tooltip: flash ? 'Flash activé' : 'Flash désactivé',
                icon: flash ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                semanticLabel: flash ? 'Désactiver le flash' : 'Activer le flash',
                filled: flash,
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(flashEnabledProvider.notifier).state = !flash;
                },
              ),
              _CaptureButton(onTap: onCapture),
              _CircleIcon(
                tooltip: front ? 'Caméra avant' : 'Caméra arrière',
                icon: Icons.cameraswitch_rounded,
                semanticLabel: 'Inverser la caméra',
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(useFrontCameraProvider.notifier).state = !front;
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    required this.semanticLabel,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final String semanticLabel;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: filled
              ? AppColors.brownMedium.withValues(alpha: 0.2)
              : AppColors.nude.withValues(alpha: 0.35),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(
                icon,
                color: AppColors.brownDark,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Capturer un cliché',
      child: Tooltip(
        message: 'Capturer',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brownMedium, width: 3),
                color: AppColors.cream,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brownDark.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brownDark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
