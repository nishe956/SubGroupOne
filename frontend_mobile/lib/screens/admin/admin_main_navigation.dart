import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/auth_provider.dart';
import 'admin_home_screen.dart';
import 'users_management_screen.dart';
import 'products_management_screen.dart';
import 'orders_management_screen.dart';
import 'prescriptions_management_screen.dart';
import 'admin_stats_screen.dart';
import 'admin_drawer.dart';

class AdminMainNavigation extends ConsumerStatefulWidget {
  const AdminMainNavigation({super.key});

  @override
  ConsumerState<AdminMainNavigation> createState() => _AdminMainNavigationState();
}

class _AdminMainNavigationState extends ConsumerState<AdminMainNavigation> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'admin';

    // Listes dynamiques selon le rôle
    final List<Widget> screens = isAdmin ? [
      AdminHomeScreen(onNavigateTab: (index) => setState(() => _selectedIndex = index)),
      const AdminUsersScreen(), // Sera filtré pour les clients dans l'écran
      const AdminStatsScreen(),
    ] : [
      AdminHomeScreen(onNavigateTab: (index) => setState(() => _selectedIndex = index)),
      const AdminProductsScreen(),
      const AdminOrdersScreen(),
      const AdminPrescriptionsScreen(),
    ];

    final List<BottomNavigationBarItem> navItems = isAdmin ? const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Clients'),
      BottomNavigationBarItem(icon: Icon(Icons.bar_chart), activeIcon: Icon(Icons.assessment), label: 'Stats'),
    ] : const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Stock'),
      BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'Orders'),
      BottomNavigationBarItem(icon: Icon(Icons.description_outlined), activeIcon: Icon(Icons.description), label: 'OCR'),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AdminDrawer(),
      appBar: _selectedIndex == 0 
          ? null 
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: AppColors.brunFonce),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(
                _getTitle(_selectedIndex, isAdmin),
                style: const TextStyle(color: AppColors.brunFonce, fontWeight: FontWeight.bold),
              ),
            ),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.brunMoyen,
        unselectedItemColor: AppColors.brunClair,
        showUnselectedLabels: true,
        items: navItems,
      ),
    );
  }

  String _getTitle(int index, bool isAdmin) {
    if (isAdmin) {
      switch (index) {
        case 1: return 'Gestion Clients';
        case 2: return 'Statistiques';
        default: return 'Admin Panel';
      }
    } else {
      switch (index) {
        case 1: return 'Stock Lunettes';
        case 2: return 'Commandes Clients';
        case 3: return 'Archives OCR';
        default: return 'Opticien Panel';
      }
    }
  }
}
