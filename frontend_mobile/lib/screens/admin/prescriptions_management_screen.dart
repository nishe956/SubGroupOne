import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../features/admin/admin_providers.dart';
import '../../../core/widgets/empty_state_widget.dart';

class AdminPrescriptionsScreen extends ConsumerStatefulWidget {
  const AdminPrescriptionsScreen({super.key});

  @override
  ConsumerState<AdminPrescriptionsScreen> createState() => _AdminPrescriptionsScreenState();
}

class _AdminPrescriptionsScreenState extends ConsumerState<AdminPrescriptionsScreen> {
  String? _searchQuery;

  @override
  Widget build(BuildContext context) {
    final prescriptionsAsync = ref.watch(adminPrescriptionsProvider(_searchQuery));

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Archives Ordonnances', style: TextStyle(color: AppColors.brunFonce)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.isEmpty ? null : value),
              decoration: InputDecoration(
                hintText: 'Rechercher un client ou un texte...',
                prefixIcon: const Icon(Icons.search, color: AppColors.brunMoyen),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: prescriptionsAsync.when(
        data: (prescriptions) => prescriptions.isEmpty 
          ? const EmptyStateWidget(
              icon: Icons.description_outlined,
              title: 'Aucune ordonnance',
              message: 'Les prescriptions scannées par les clients apparaîtront ici pour votre suivi.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: prescriptions.length,
              itemBuilder: (context, index) {
                final prescription = prescriptions[index];
                return _PrescriptionCard(prescription: prescription);
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final Map<String, dynamic> prescription;
  const _PrescriptionCard({required this.prescription});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(prescription['date_scan']);
    final formattedDate = DateFormat('dd MMM yyyy').format(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.description_outlined, color: AppColors.brunMoyen, size: 30),
        title: Text('Ordonnance du $formattedDate', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          prescription['texte_extrait'] ?? 'Aucun texte extrait.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.brunClair),
        onTap: () {
          _showPrescriptionDetail(context);
        },
      ),
    );
  }

  void _showPrescriptionDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Détails de l\'ordonnance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Texte détecté:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brunMoyen)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
                      child: Text(prescription['texte_extrait'] ?? 'Pas de texte'),
                    ),
                    const SizedBox(height: 24),
                    const Text('Informations patient (OCR):', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brunMoyen)),
                    const SizedBox(height: 12),
                    _detailRow('Email Client', prescription['user_email'] ?? 'Non fourni'),
                    _detailRow('Date du Scan', prescription['date_scan']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.brunClair)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
