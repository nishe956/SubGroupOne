import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'ocr_providers.dart';
import 'ocr_result_screen.dart';

/// Écran de scan façon « document scanner » contemporain (UI seulement).
class OcrScanScreen extends ConsumerStatefulWidget {
  const OcrScanScreen({super.key});

  @override
  ConsumerState<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends ConsumerState<OcrScanScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _sweep.dispose();
    super.dispose();
  }

  Future<void> _simulateScan() async {
    ref.read(ocrScanBusyProvider.notifier).state = true;
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    ref.read(ocrExtractedTextProvider.notifier).state =
        'Monture : Atelier Nude — Optique\n'
        'PD : 62 mm\n'
        'Réf. fabricant : ATN-901\n'
        'Verre conseillé : Blue UV 1.6\n\n'
        '(Exemple statique — branchez votre OCR ici.)';
    ref.read(ocrScanBusyProvider.notifier).state = false;
    if (!mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const OcrResultScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(ocrScanBusyProvider);

    return Scaffold(
      backgroundColor: AppColors.brownDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Scan'),
      ),
      body: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.brownDark, Color(0xFF2A2118)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SizedBox.expand(),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: AspectRatio(
                aspectRatio: 3 / 4.2,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulse, _sweep]),
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ScannerFramePainter(
                        pulse: _pulse.value,
                        sweep: _sweep.value,
                      ),
                      child: const SizedBox.expand(),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cream,
                foregroundColor: AppColors.brownDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: busy ? null : _simulateScan,
              icon: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brownDark,
                      ),
                    )
                  : const Icon(Icons.document_scanner_outlined),
              label: Text(busy ? 'Analyse…' : 'Numériser le document'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  _ScannerFramePainter({required this.pulse, required this.sweep});

  final double pulse;
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));
    final inner =
        RRect.fromRectAndRadius(rect.deflate(22), const Radius.circular(16));

    final dim = Paint()..color = Colors.black.withValues(alpha: 0.42);
    canvas.drawDRRect(rrect, inner, dim);

    final border = Paint()
      ..color = AppColors.cream.withValues(alpha: 0.25 + pulse * 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(rrect, border);

    final corner = Paint()
      ..color = AppColors.cream
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 26.0;
    void cornerLines(Offset o, bool top, bool left) {
      final path = Path();
      if (top && left) {
        path.moveTo(o.dx, o.dy + len);
        path.lineTo(o.dx, o.dy);
        path.lineTo(o.dx + len, o.dy);
      } else if (top && !left) {
        path.moveTo(o.dx - len, o.dy);
        path.lineTo(o.dx, o.dy);
        path.lineTo(o.dx, o.dy + len);
      } else if (!top && left) {
        path.moveTo(o.dx, o.dy - len);
        path.lineTo(o.dx, o.dy);
        path.lineTo(o.dx + len, o.dy);
      } else {
        path.moveTo(o.dx - len, o.dy);
        path.lineTo(o.dx, o.dy);
        path.lineTo(o.dx, o.dy - len);
      }
      canvas.drawPath(path, corner);
    }

    final pad = 10.0;
    cornerLines(rect.topLeft + Offset(pad, pad), true, true);
    cornerLines(rect.topRight + Offset(-pad, pad), true, false);
    cornerLines(rect.bottomLeft + Offset(pad, -pad), false, true);
    cornerLines(rect.bottomRight + Offset(-pad, -pad), false, false);

    final scanY = rect.top + sweep * rect.height;
    final scan = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.brownLight.withValues(alpha: 0.0),
          AppColors.cream.withValues(alpha: 0.45),
          AppColors.brownLight.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(rect.left, scanY - 8, rect.width, 16));
    canvas.drawRect(
      Rect.fromLTWH(rect.left, scanY - 2, rect.width, 4),
      scan,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter oldDelegate) =>
      oldDelegate.pulse != pulse || oldDelegate.sweep != sweep;
}
