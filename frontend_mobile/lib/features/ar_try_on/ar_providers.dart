import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contrôleur caméra — à initialiser et disposer via votre couche technique.
/// Tant qu’il est `null`, l’UI affiche un placeholder plein écran élégant.
final cameraControllerProvider =
    StateProvider<CameraController?>((ref) => null);

/// Flash (UI) — la bascule réelle du flash reste côté service caméra.
final flashEnabledProvider = StateProvider<bool>((ref) => false);

/// `true` = caméra frontale, `false` = arrière (commutateur visuel).
final useFrontCameraProvider = StateProvider<bool>((ref) => true);

/// Échelle de l’overlay lunettes (sera pilotée par la logique AR).
final glassesOverlayScaleProvider = StateProvider<double>((ref) => 1.0);

/// Décalage normalisé du centre (-1..1) pour preview futur.
final glassesOverlayOffsetProvider =
    StateProvider<OffsetSnapshot>((ref) => const OffsetSnapshot(0, 0));

/// Valeur simple sérialisable pour éviter [Offset] mutable dans le provider.
class OffsetSnapshot {
  const OffsetSnapshot(this.dx, this.dy);
  final double dx;
  final double dy;
}
