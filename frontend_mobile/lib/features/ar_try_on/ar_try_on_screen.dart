import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';

import '../products/product.dart';
import '../theme/app_theme.dart';
import 'ar_providers.dart';
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
  bool _showFlash = false;
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
    } else {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final useFront = ref.read(useFrontCameraProvider);
    final selectedCamera = cameras.firstWhere(
      (c) =>
          c.lensDirection ==
          (useFront ? CameraLensDirection.front : CameraLensDirection.back),
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      selectedCamera,
      ResolutionPreset.max,
      enableAudio: false,
    );

    await controller.initialize();
    if (mounted) {
      ref.read(cameraControllerProvider.notifier).state = controller;
    }
  }

  @override
  void dispose() {
    final controller = ref.read(cameraControllerProvider);
    controller?.dispose();
    super.dispose();
  }

  void _demoAdjustScale() {
    final current = ref.read(glassesOverlayScaleProvider);
    final next = (current >= 1.12) ? 0.92 : current + 0.06;
    ref.read(glassesOverlayScaleProvider.notifier).state =
        next.clamp(0.85, 1.2);
  }

  Future<void> _handleCapture() async {
    final controller = ref.read(cameraControllerProvider);
    if (controller == null || !controller.value.isInitialized) return;

    try {
      setState(() => _showFlash = true);
      HapticFeedback.heavyImpact();
      
      final image = await controller.takePicture();
      
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _showFlash = false);
      });

      if (!mounted) return;

      // --- AJOUT : Synchronisation Backend IA ---
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Analyse IA en cours..."),
                ],
              ),
            ),
          ),
        ),
      );

      final formData = dio.FormData.fromMap({
        'monture_id': widget.product.id,
        'image': await dio.MultipartFile.fromFile(image.path),
      });

      final response = await apiClient.post(
        ApiEndpoints.tryOn,
        data: formData,
      );

      if (mounted) Navigator.of(context).pop(); // Fermer le loading

      if (response.statusCode == 201 && mounted) {
        final resultImageUrl = response.data['image_resultat'];
        
        if (resultImageUrl != null) {
          _showResultDialog(resultImageUrl);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Essai enregistré, mais le rendu IA a échoué.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        setState(() => _showFlash = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'essai IA : $e')),
        );
      }
    }
  }

  void _showResultDialog(String imagePath) {
    final fullUrl = '${ApiEndpoints.baseUrl.replaceAll('/api', '')}/media/$imagePath';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Résultat de l\'essai'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                fullUrl,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Les lunettes ont été ajustées à votre visage par notre IA.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Génial !'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final controller = ref.watch(cameraControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.brownDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && controller.value.isInitialized) ...[
            Positioned.fill(
              child: CameraPreview(controller),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: FaceGuidePainter(),
              ),
            ),
            Positioned.fill(
              child: GlassesOverlay(
                product: product,
              ),
            ),
          ] else
            const Center(child: CircularProgressIndicator()),
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
              onCapture: _handleCapture,
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

/// Dessine une silhouette de visage pour aider à l'alignement.
class FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final path = Path();
    
    // Ovale pour le visage
    path.addOval(Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2.1),
      width: size.width * 0.65,
      height: size.height * 0.45,
    ));

    // Ligne pour les yeux
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.45),
      Offset(size.width * 0.7, size.height * 0.45),
      paint..strokeWidth = 1.0,
    );

    canvas.drawPath(path, paint);
    
    // Texte indicatif
    const textPainter = TextSpan(
      text: "Alignez vos yeux ici",
      style: TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
    final tp = TextPainter(
      text: textPainter,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, size.height * 0.3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
