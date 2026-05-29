import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'ar_providers.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({
    super.key,
    this.overlay,
    this.placeholderLabel = 'Ouverture du miroir…',
  });

  final Widget? overlay;
  final String placeholderLabel;

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty || !mounted) return;
      final cam = cameras.first;
      final controller = CameraController(
        cam,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      ref.read(cameraControllerProvider.notifier).state = controller;
    } catch (_) {
      // Caméra non disponible
    }
  }

  @override
  void dispose() {
    ref.read(cameraControllerProvider)?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.watch(cameraControllerProvider);
    final isReady = ctrl != null &&
        ctrl.value.isInitialized &&
        !ctrl.value.hasError;

    return LayoutBuilder(
      builder: (context, c) {
        return ColoredBox(
          color: AppColors.brownDark,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isReady)
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: ctrl.value.previewSize?.height ?? c.maxWidth,
                    height: ctrl.value.previewSize?.width ?? c.maxHeight,
                    child: CameraPreview(ctrl),
                  ),
                )
              else
                _LuxuryCameraPlaceholder(message: widget.placeholderLabel),
              if (widget.overlay != null) widget.overlay!,
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
