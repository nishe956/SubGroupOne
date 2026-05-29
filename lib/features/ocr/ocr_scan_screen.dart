import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';
import '../../core/services/ordonnances_service.dart';
import '../theme/app_theme.dart';
import 'ocr_providers.dart';
import 'ocr_result_screen.dart';

class OcrScanScreen extends ConsumerStatefulWidget {
  const OcrScanScreen({super.key});

  @override
  ConsumerState<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends ConsumerState<OcrScanScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _sweep;

  /// Chemin du dernier fichier sélectionné pour le scan.
  String? _selectedImagePath;

  /// Instance du picker.
  final ImagePicker _picker = ImagePicker();

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

  /// Ouvre un bottom sheet pour choisir la source de l'image.
  Future<void> _choisirSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.brownLight.withValues(alpha: 0.55),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Source de l\'image',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brownDark,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choisissez d\'où importer votre ordonnance.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: AppColors.brownDark.withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: 20),
              _SourceOption(
                icon: Icons.camera_alt_rounded,
                label: 'Appareil photo',
                subtitle: 'Prendre une photo de l\'ordonnance',
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 10),
              _SourceOption(
                icon: Icons.photo_library_rounded,
                label: 'Galerie',
                subtitle: 'Choisir une image existante',
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );

    if (image == null || !mounted) return;

    setState(() => _selectedImagePath = image.path);
    await _scanOrdonnance();
  }

  /// Tente le scan via le backend OCR.
  /// En cas d'échec réseau, utilise les données de démonstration.
  Future<void> _scanOrdonnance() async {
    ref.read(ocrScanBusyProvider.notifier).state = true;

    final isLoggedIn = await ApiClient.isLoggedIn();

    if (isLoggedIn && _selectedImagePath != null) {
      // ── Appel backend réel ──
      try {
        final result = await OrdonnancesService.scanner(
          imagePath: _selectedImagePath!,
        );

        if (!mounted) {
          ref.read(ocrScanBusyProvider.notifier).state = false;
          return;
        }

        if (result.isSuccess && result.data != null) {
          final data = result.data!;
          final texteDetecte = data['texte_detecte'] as String? ?? '';
          final valeurs = data['valeurs_extraites'] as Map<String, dynamic>?;

          final sb = StringBuffer();
          if (texteDetecte.isNotEmpty) {
            sb.writeln('Texte détecté :');
            sb.writeln(texteDetecte);
            sb.writeln();
          }
          if (valeurs != null) {
            sb.writeln('── Valeurs optiques extraites ──');
            sb.writeln('Œil droit :');
            sb.writeln('  Sphère   : ${valeurs['oeil_droit_sphere'] ?? '—'}');
            sb.writeln('  Cylindre : ${valeurs['oeil_droit_cylindre'] ?? '—'}');
            sb.writeln('  Axe      : ${valeurs['oeil_droit_axe'] ?? '—'}');
            sb.writeln();
            sb.writeln('Œil gauche :');
            sb.writeln('  Sphère   : ${valeurs['oeil_gauche_sphere'] ?? '—'}');
            sb.writeln('  Cylindre : ${valeurs['oeil_gauche_cylindre'] ?? '—'}');
            sb.writeln('  Axe      : ${valeurs['oeil_gauche_axe'] ?? '—'}');
          }

          ref.read(ocrExtractedTextProvider.notifier).state = sb.toString();
          ref.read(ocrScanBusyProvider.notifier).state = false;

          await Navigator.of(context).push(
            PageRouteBuilder<void>(
              pageBuilder: (_, __, ___) => const OcrResultScreen(),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          );
          return;
        }
      } catch (_) {
        // Fallback sur données de démo en cas d'erreur
      }
    }

    // ── Fallback : données de démonstration ──
    await Future<void>.delayed(const Duration(milliseconds: 1600));

    if (!mounted) {
      ref.read(ocrScanBusyProvider.notifier).state = false;
      return;
    }

    ref.read(ocrExtractedTextProvider.notifier).state =
        '── Valeurs optiques extraites (démo) ──\n\n'
        'Œil droit :\n'
        '  Sphère   : -1.75\n'
        '  Cylindre : -0.50\n'
        '  Axe      : 170°\n\n'
        'Œil gauche :\n'
        '  Sphère   : -2.00\n'
        '  Cylindre : -0.25\n'
        '  Axe      : 15°\n\n'
        'PD : 63 mm\n'
        'Médecin : Dr. Leroux\n\n'
        '(Démo statique — connectez-vous et fournissez une image '
        'pour lancer l\'OCR réel.)';
    ref.read(ocrScanBusyProvider.notifier).state = false;

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
    final isBusy = ref.watch(ocrScanBusyProvider);

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
                      child: _selectedImagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                _selectedImagePath!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.expand(),
                              ),
                            )
                          : const SizedBox.expand(),
                    );
                  },
                ),
              ),
            ),
          ),
          // ── Indication réseau ──
          Positioned(
            left: 24,
            right: 24,
            top: MediaQuery.of(context).padding.top + 56,
            child: FutureBuilder<bool>(
              future: ApiClient.isLoggedIn(),
              builder: (ctx, snap) {
                final loggedIn = snap.data ?? false;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.cream.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        loggedIn
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_off_outlined,
                        size: 18,
                        color: AppColors.cream.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loggedIn
                              ? 'OCR backend connecté'
                              : 'Mode démo — connectez-vous pour l\'OCR réel',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.cream.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // ── Indication image sélectionnée ──
          if (_selectedImagePath != null)
            Positioned(
              left: 24,
              right: 24,
              top: MediaQuery.of(context).padding.top + 100,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.image_rounded,
                      size: 18,
                      color: AppColors.cream.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Image sélectionnée ✓',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.cream.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
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
              onPressed: isBusy ? null : _choisirSource,
              icon: isBusy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brownDark,
                      ),
                    )
                  : const Icon(Icons.document_scanner_outlined),
              label: Text(isBusy ? 'Analyse…' : 'Numériser le document'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Option dans le bottom sheet de choix de source d'image.
class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.nude.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brownMedium,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.cream, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.brownDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.brownDark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
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

    const pad = 10.0;
    cornerLines(rect.topLeft + const Offset(pad, pad), true, true);
    cornerLines(rect.topRight + const Offset(-pad, pad), true, false);
    cornerLines(rect.bottomLeft + const Offset(pad, -pad), false, true);
    cornerLines(rect.bottomRight + const Offset(-pad, -pad), false, false);

    final scanY = rect.top + sweep * rect.height;
    final scan = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.brownLight.withValues(alpha: 0.0),
          AppColors.cream.withValues(alpha: 0.45),
          AppColors.brownLight.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(rect.left, scanY - 8, rect.width, 16));
    canvas.drawRect(Rect.fromLTWH(rect.left, scanY - 2, rect.width, 4), scan);
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter oldDelegate) =>
      oldDelegate.pulse != pulse || oldDelegate.sweep != sweep;
}
