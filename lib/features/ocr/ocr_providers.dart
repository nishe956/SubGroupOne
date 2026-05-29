import 'package:flutter_riverpod/flutter_riverpod.dart';

/// true pendant l'analyse OCR.
final ocrScanBusyProvider = StateProvider<bool>((ref) => false);

/// Texte extrait par le moteur OCR (vide par défaut).
final ocrExtractedTextProvider = StateProvider<String>((ref) => '');
