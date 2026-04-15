import 'package:flutter/material.dart';
import '../../core/api/api_endpoints.dart';

class ProductImageLoader extends StatelessWidget {
  const ProductImageLoader({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.errorBuilder,
  });

  final String imagePath;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final double? width;
  final double? height;
  final ImageErrorWidgetBuilder? errorBuilder;

  /// Détermine si le chemin est une image réseau (HTTP ou relative à Django /media/)
  bool get _isNetworkImage =>
      imagePath.startsWith('http') || imagePath.startsWith('/media');

  /// Calcule l'URL complète si l'URL est relative (ex: /media/montures/image.png)
  String get _fullNetworkUrl {
    if (imagePath.startsWith('http')) return imagePath;

    // ApiEndpoints.baseUrl ressemble à http://192.168.x.x:8000/api
    // On veut la base sans '/api' donc on coupe avant le '/api'
    final hostUrl = ApiEndpoints.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    return '$hostUrl$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    if (_isNetworkImage) {
      return Image.network(
        _fullNetworkUrl,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
      );
    } else {
      return Image.asset(
        imagePath,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
      );
    }
  }
}
