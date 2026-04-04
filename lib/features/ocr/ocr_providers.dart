import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Texte extrait — alimenté par votre pipeline OCR (non implémenté ici).
final ocrExtractedTextProvider = StateProvider<String>((ref) => '');

/// État visuel « scan en cours » (animation, loading overlay).
final ocrScanBusyProvider = StateProvider<bool>((ref) => false);
