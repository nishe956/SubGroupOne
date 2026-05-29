import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Scale de l'overlay lunettes (1.0 = taille normale).
final glassesOverlayScaleProvider = StateProvider<double>((ref) => 1.0);

/// Décalage de l'overlay (en « unités de nudge »).
final glassesOverlayOffsetXProvider = StateProvider<double>((ref) => 0.0);
final glassesOverlayOffsetYProvider = StateProvider<double>((ref) => 0.0);

/// Flash actif ou non.
final flashEnabledProvider = StateProvider<bool>((ref) => false);

/// true = caméra avant, false = caméra arrière.
final useFrontCameraProvider = StateProvider<bool>((ref) => true);

/// Contrôleur de caméra courant — null tant que non initialisé.
final cameraControllerProvider = StateProvider<CameraController?>((ref) => null);
