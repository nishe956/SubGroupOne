import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class OrdonnanceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> ordonnance;

  const OrdonnanceDetailScreen({super.key, required this.ordonnance});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Détail Ordonnance', style: TextStyle(color: AppColors.brunFonce)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brunMoyen),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview Card
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ordonnance['image'] != null
                    ? Image.network(
                        ordonnance['image'],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 50, color: AppColors.brunClair)),
                      )
                    : const Center(child: Icon(Icons.image_not_supported, size: 50, color: AppColors.brunClair)),
              ),
            ),
            const SizedBox(height: 32),

            // Extracted Info Table
            const Text('Informations Optiques', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brunFonce)),
            const SizedBox(height: 16),
            _buildOpticalTable(),
            
            const SizedBox(height: 32),
            const Text('Commentaire Opticien / Expert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brunFonce)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Les données ont été extraites automatiquement par notre système IA. Veuillez confirmer ces informations avec votre opticien lors du choix de vos verres.',
                style: TextStyle(color: AppColors.brunMoyen, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOpticalTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          border: TableBorder.all(color: AppColors.nudeSable, width: 0.5),
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            1: IntrinsicColumnWidth(),
            2: IntrinsicColumnWidth(),
            3: IntrinsicColumnWidth(),
          },
          children: [
            _buildRow(['Œil', 'Sphère', 'Cylindre', 'Axe'], isHeader: true),
            _buildRow([
              'OD (Droit)', 
              '${ordonnance['sphere_od'] ?? '-'}', 
              '${ordonnance['cylindre_od'] ?? '-'}', 
              '${ordonnance['axe_od'] ?? '-'}'
            ]),
            _buildRow([
              'OG (Gauche)', 
              '${ordonnance['sphere_og'] ?? '-'}', 
              '${ordonnance['cylindre_og'] ?? '-'}', 
              '${ordonnance['axe_og'] ?? '-'}'
            ]),
            _buildRow([
              'Addition',
              '${ordonnance['addition'] ?? '-'}',
              '',
              ''
            ]),
          ],
        ),
      ),
    );
  }

  TableRow _buildRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      children: cells.map((cell) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            cell,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              color: isHeader ? AppColors.brunFonce : AppColors.brunMoyen,
              fontSize: isHeader ? 14 : 13,
            ),
          ),
        );
      }).toList(),
    );
  }
}
