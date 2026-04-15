import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/admin/admin_main_navigation.dart';
import 'features/auth/auth_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Glasses Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _getHome(authState),
    );
  }

  Widget _getHome(AuthState state) {
    if (state.user == null) {
      return const LoginScreen();
    }
    
    final role = state.user?.role;
    if (role == 'admin' || role == 'opticien') {
      return const AdminMainNavigation();
    }
    
    return const MainNavigation();
  }
}
