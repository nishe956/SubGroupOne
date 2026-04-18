import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../products/product.dart';
import '../theme/app_theme.dart';
import '../../core/widgets/product_image_loader.dart';
import 'ar_providers.dart';

/// Overlay « lunettes » élégant — rendu purement visuel en attendant l’IA.
class GlassesOverlay extends ConsumerWidget {
  const GlassesOverlay({
    super.key,
    required this.product,
    this.showGuides = true,
  });

  final Product product;
  final bool showGuides;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(glassesOverlayScaleProvider);
    final off = ref.watch(glassesOverlayOffsetProvider);

    return IgnorePointer(
      ignoring: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showGuides) const _SubtleVignette(),
          Center(
            child: Transform.translate(
              offset: Offset(off.dx * 36, off.dy * 24),
              child: Transform.scale(
                scale: scale,
                  child: SizedBox(
                    width: 320,
                    child: ProductImageLoader(
                      imagePath: product.imageAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => _GlassesFrameSilhouette(
                        accent: product.heroGradient.isNotEmpty
                            ? product.heroGradient.first
                            : AppColors.brownMedium,
                      ),
                    ),
                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtleVignette extends StatelessWidget {
  const _SubtleVignette();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Color(0x33000000),
          ],
          begin: Alignment.center,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _GlassesFrameSilhouette extends StatelessWidget {
  const _GlassesFrameSilhouette({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlassesPainter(accent: accent),
      size: const Size(320, 120),
    );
  }
}

class _GlassesPainter extends CustomPainter {
  _GlassesPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = AppColors.cream.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;

    final strokeThin = Paint()
      ..color = AppColors.cream.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = accent.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final ry = h * 0.38;
    final rx = w * 0.2;

    void drawLens(double ox) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + ox, h * 0.5),
          width: rx * 2,
          height: ry * 2,
        ),
        Radius.circular(h * 0.32),
      );
      canvas.drawRRect(r, fill);
      canvas.drawRRect(r, stroke);
    }

    drawLens(-w * 0.18);
    drawLens(w * 0.18);

    final bridge = Path()
      ..moveTo(cx - w * 0.06, h * 0.48)
      ..quadraticBezierTo(cx, h * 0.42, cx + w * 0.06, h * 0.48);
    canvas.drawPath(
      bridge,
      stroke,
    );

    final templeL = Path()
      ..moveTo(cx - w * 0.38, h * 0.5)
      ..lineTo(0, h * 0.46);
    final templeR = Path()
      ..moveTo(cx + w * 0.38, h * 0.5)
      ..lineTo(w, h * 0.46);
    canvas.drawPath(templeL, strokeThin);
    canvas.drawPath(templeR, strokeThin);
  }

  @override
  bool shouldRepaint(covariant _GlassesPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
