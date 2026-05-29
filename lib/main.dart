import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/auth_provider.dart';
import 'features/products/products_list_screen.dart';
import 'features/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: EstherApp(),
    ),
  );
}

class EstherApp extends ConsumerStatefulWidget {
  const EstherApp({super.key});

  @override
  ConsumerState<EstherApp> createState() => _EstherAppState();
}

class _EstherAppState extends ConsumerState<EstherApp> {
  @override
  void initState() {
    super.initState();
    // Vérifie si l'utilisateur est déjà connecté (token stocké).
    Future.microtask(() {
      ref.read(authProvider.notifier).checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Esther',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: _buildHome(authState),
    );
  }

  Widget _buildHome(AuthState authState) {
    switch (authState.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        // Écran de chargement pendant la vérification du token.
        return const Scaffold(
          backgroundColor: AppColors.cream,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.visibility_rounded,
                  size: 48,
                  color: AppColors.brownMedium,
                ),
                SizedBox(height: 20),
                CircularProgressIndicator(
                  color: AppColors.brownMedium,
                  strokeWidth: 2,
                ),
              ],
            ),
          ),
        );

      case AuthStatus.authenticated:
        // Utilisateur connecté → catalogue directement.
        return const ProductsListScreen();

      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        // Non connecté → catalogue accessible (mode invité possible).
        // L'utilisateur peut se connecter depuis la barre d'actions.
        return const ProductsListScreen();
    }
  }
}
