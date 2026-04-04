import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'ar_providers.dart';

/// Zone de prévisualisation plein écran.
/// Affiche [CameraPreview] si un [CameraController] valide est fourni via
/// [cameraControllerProvider], sinon un placeholder premium.
class CameraScreen extends ConsumerWidget {
  const CameraScreen({
    super.key,
    this.overlay,
    this.placeholderLabel = 'Ouverture du miroir…',
  });

  /// Calque AR (lunettes, guides…) — optionnel.
  final Widget? overlay;

  /// Texte sous le pictogramme lorsque la caméra n’est pas branchée.
  final String placeholderLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(cameraControllerProvider);
    final isReady = controller != null &&
        controller.value.isInitialized &&
        !controller.value.hasError;

    return LayoutBuilder(
      builder: (context, c) {
        return ColoredBox(
          color: AppColors.brownDark,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isReady)
                Builder(
                  builder: (_) {
                    final cam = controller;
                    return FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width:
                            cam.value.previewSize?.height ?? c.maxWidth,
                        height:
                            cam.value.previewSize?.width ?? c.maxHeight,
                        child: CameraPreview(cam),
                      ),
                    );
                  },
                )
              else
                _LuxuryCameraPlaceholder(message: placeholderLabel),
              if (overlay != null) overlay!,
            ],
          ),
        );
      },
    );
  }
}

class _LuxuryCameraPlaceholder extends StatelessWidget {
  const _LuxuryCameraPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brownDark, Color(0xFF2C2218)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.brownLight.withValues(alpha: 0.35),
                ),
                color: AppColors.brownMedium.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.photo_camera_outlined,
                size: 48,
                color: AppColors.cream,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.cream.withValues(alpha: 0.92),
                    letterSpacing: 0.3,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'La prévisualisation sera affichée ici.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.cream.withValues(alpha: 0.55),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
