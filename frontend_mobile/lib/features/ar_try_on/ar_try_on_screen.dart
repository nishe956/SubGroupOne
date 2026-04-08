import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../products/product.dart';
import '../theme/app_theme.dart';
import 'ar_providers.dart';
import 'camera_screen.dart';
import 'glasses_overlay.dart';
import 'widgets/ar_control_sheet.dart';

/// Expérience AR complète — prévisualisation, overlay, contrôles.
class ArTryOnScreen extends ConsumerStatefulWidget {
  const ArTryOnScreen({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<ArTryOnScreen> createState() => _ArTryOnScreenState();
}

class _ArTryOnScreenState extends ConsumerState<ArTryOnScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePermissions());
  }

  Future<void> _ensurePermissions() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isDenied || status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Autorisez la caméra dans les réglages pour voir la prévisualisation.',
          ),
          action: SnackBarAction(
            label: 'Réglages',
            onPressed: openAppSettings,
          ),
        ),
      );
    }
  }

  void _demoAdjustScale() {
    final current = ref.read(glassesOverlayScaleProvider);
    final next = (current >= 1.12) ? 0.92 : current + 0.06;
    ref.read(glassesOverlayScaleProvider.notifier).state =
        next.clamp(0.85, 1.2);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppColors.brownDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CameraScreen(
              overlay: GlassesOverlay(product: product),
              placeholderLabel: 'Connexion caméra…',
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 20,
            right: 20,
            child: _ArTopHint(
              productName: product.name,
              onDemoNudge: _demoAdjustScale,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ArControlSheet(
              onClose: () => Navigator.of(context).maybePop(),
              onCapture: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Capture — branchez votre pipeline photo ici.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ArTopHint extends StatelessWidget {
  const _ArTopHint({
    required this.productName,
    required this.onDemoNudge,
  });

  final String productName;
  final VoidCallback onDemoNudge;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: AppColors.cream.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Essayage',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.6,
                            color: AppColors.brownMedium,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onDemoNudge,
                child: const Text('Ajuster'),
              ),
            ],
          ),
        ),
    );
  }
}
