import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/products/products_list_screen.dart';
import 'features/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: EstherApp()));
}

class EstherApp extends StatelessWidget {
  const EstherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Esther',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const ProductsListScreen(),
    );
  }
}
