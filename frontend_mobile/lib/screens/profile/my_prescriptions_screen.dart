import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../features/ocr/ocr_service.dart';
import 'ordonnance_detail_screen.dart';

class MyPrescriptionsScreen extends ConsumerStatefulWidget {
  const MyPrescriptionsScreen({super.key});

  @override
  ConsumerState<MyPrescriptionsScreen> createState() => _MyPrescriptionsScreenState();
}

class _MyPrescriptionsScreenState extends ConsumerState<MyPrescriptionsScreen> {
  late Future<List<dynamic>> _prescriptionsFuture;

  @override
  void initState() {
    super.initState();
    _prescriptionsFuture = ref.read(ocrServiceProvider).getUserPrescriptions();
  }

  void _refreshPrescriptions() {
    setState(() {
      _prescriptionsFuture = ref.read(ocrServiceProvider).getUserPrescriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Mes Ordonnances', style: TextStyle(color: AppColors.brunFonce, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brunMoyen),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshPrescriptions(),
        child: FutureBuilder<List<dynamic>>(
          future: _prescriptionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.description_outlined, size: 80, color: AppColors.brunClair),
                    const SizedBox(height: 16),
                    const Text('Aucune ordonnance scannée', style: TextStyle(color: AppColors.brunMoyen, fontSize: 16)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.brunMoyen),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('RETOUR', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            }

            final prescriptions = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: prescriptions.length,
              itemBuilder: (context, index) {
                final ord = prescriptions[index];
                final date = DateTime.parse(ord['date_scan']);
                final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrdonnanceDetailScreen(ordonnance: ord),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.nudeSable.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.description, color: AppColors.brunMoyen, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan du $formattedDate',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.brunFonce),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Appuyez pour voir les détails optiques',
                                style: TextStyle(color: AppColors.brunClair, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.brunClair),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
