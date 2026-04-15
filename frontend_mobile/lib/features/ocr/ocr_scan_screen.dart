import 'package:dio/dio.dart' as dio;
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
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
  CameraController? _cameraController;
  late final AnimationController _pulse;
  late final AnimationController _sweep;
  bool _showFlash = false;

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
    
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!mounted || status.isDenied) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final selectedCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      selectedCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller.initialize();
    if (mounted) {
      setState(() {
        _cameraController = controller;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulse.dispose();
    _sweep.dispose();
    super.dispose();
  }

  Future<void> _captureAndScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    ref.read(ocrScanBusyProvider.notifier).state = true;
    
    try {
      setState(() => _showFlash = true);
      final image = await _cameraController!.takePicture();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _showFlash = false);
      });
      HapticFeedback.mediumImpact();

      final formData = dio.FormData.fromMap({
        'image': await dio.MultipartFile.fromFile(image.path),
      });

      final response = await apiClient.post(
        ApiEndpoints.scanPrescription,
        data: formData,
      );

      if (response.statusCode == 201 && mounted) {
        final text = response.data['texte_extrait'] ?? 'Aucun texte détecté.';
        ref.read(ocrExtractedTextProvider.notifier).state = text;
        
        Navigator.of(context).push(
          PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) => const OcrResultScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du scan de l\'ordonnance.')),
        );
      }
    } finally {
      ref.read(ocrScanBusyProvider.notifier).state = false;
    }
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
          if (_cameraController != null && _cameraController!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                   width: _cameraController!.value.previewSize?.height ?? MediaQuery.of(context).size.width,
                   height: _cameraController!.value.previewSize?.width ?? MediaQuery.of(context).size.height,
                   child: CameraPreview(_cameraController!),
                ),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x993D2E20), Color(0x992A2118)],
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
              onPressed: busy ? null : _captureAndScan,
              icon: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brownDark,
                      ),
                    )
                  : const Icon(Icons.photo_camera_rounded),
              label: Text(busy ? 'Analyse…' : 'Prendre une photo'),
            ),
          ),
          if (_showFlash)
            Positioned.fill(
              child: Container(
                color: Colors.white,
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
