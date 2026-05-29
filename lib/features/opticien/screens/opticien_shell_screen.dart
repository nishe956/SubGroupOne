import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/commande_opticien.dart';
import '../providers/commandes_opticien_provider.dart';
import 'gestion_commandes_screen.dart';
import 'gestion_montures_screen.dart';
import 'opticien_dashboard_screen.dart';
import 'profil_opticien_screen.dart';

/// Provider pour l'index de l'onglet actif dans le shell opticien.
/// Permet au dashboard (et autres écrans enfants) de changer d'onglet.
final opticienTabProvider = StateProvider<int>((ref) => 0);

class OpticienShellScreen extends ConsumerWidget {
  const OpticienShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(opticienTabProvider);
    final commandes = ref.watch(commandesOpticienProvider);
    final enAttente =
        commandes.where((c) => c.statut == StatutCommande.enAttente).length;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          OpticienDashboardScreen(),
          GestionMonturesScreen(),
          GestionCommandesScreen(),
          ProfilOpticienScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) =>
            ref.read(opticienTabProvider.notifier).state = i,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.remove_red_eye_outlined),
            selectedIcon: Icon(Icons.remove_red_eye_rounded),
            label: 'Montures',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: enAttente > 0,
              label: Text('$enAttente'),
              backgroundColor: const Color(0xFFB8860B),
              textColor: Colors.white,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: const Icon(Icons.shopping_bag_rounded),
            label: 'Commandes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
