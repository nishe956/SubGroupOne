import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../models/commande_opticien.dart';
import '../widgets/opticien_widgets.dart';

/// Écran de consultation des ordonnances reçues.
/// Reçoit la liste en paramètre — UI pure, aucun provider.
class ConsultationOrdonnancesScreen extends StatelessWidget {
  const ConsultationOrdonnancesScreen({super.key, required this.commandes});

  final List<CommandeOpticien> commandes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ordonnances')),
      body: commandes.isEmpty
          ? const EstherErrorWidget(message: 'Aucune ordonnance reçue pour le moment.')
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: commandes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _OrdonnanceTile(commande: commandes[i]),
            ),
    );
  }
}

class _OrdonnanceTile extends StatelessWidget {
  const _OrdonnanceTile({required this.commande});

  final CommandeOpticien commande;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${commande.dateCommande.day.toString().padLeft(2, '0')}/'
        '${commande.dateCommande.month.toString().padLeft(2, '0')}/'
        '${commande.dateCommande.year}';

    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => _OrdonnancePleinEcran(commande: commande),
          ));
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.brownLight.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64, height: 52,
                  child: Image.asset(commande.ordonnance.imageAsset, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.nude,
                          child: const Icon(Icons.document_scanner_outlined,
                              color: AppColors.brownMedium, size: 28))),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(commande.nomClient, style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.brownDark)),
                const SizedBox(height: 3),
                Text(dateStr, style: TextStyle(
                    fontSize: 12, color: AppColors.brownDark.withValues(alpha: 0.6))),
              ])),
              StatutBadge(statut: commande.statut, compact: true),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: AppColors.brownLight.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdonnancePleinEcran extends StatelessWidget {
  const _OrdonnancePleinEcran({required this.commande});

  final CommandeOpticien commande;

  @override
  Widget build(BuildContext context) {
    final ord = commande.ordonnance;

    return Scaffold(
      backgroundColor: AppColors.brownDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.cream,
        elevation: 0,
        title: Text('Ordonnance — ${commande.nomClient}',
            style: const TextStyle(color: AppColors.cream)),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5.0,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(ord.imageAsset, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          width: double.infinity, height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.brownMedium.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.document_scanner_outlined, color: AppColors.cream, size: 48),
                            SizedBox(height: 12),
                            Text('Image non disponible', style: TextStyle(color: AppColors.cream)),
                          ]),
                        )),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Données extraites (OCR)', style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.brownDark)),
                  const Divider(height: 20),
                  Table(
                    border: TableBorder.all(
                        color: AppColors.brownLight.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8)),
                    columnWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)},
                    children: [
                      _row(['', 'OD', 'OG'], header: true),
                      _row(['Sphère', ord.odSphere ?? '—', ord.ogSphere ?? '—']),
                      _row(['Cylindre', ord.odCylindre ?? '—', ord.ogCylindre ?? '—']),
                      _row(['Axe', ord.odAxe ?? '—', ord.ogAxe ?? '—']),
                      _row(['Addition', ord.odAddition ?? '—', ord.ogAddition ?? '—']),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (ord.pd != null) InfoRow(label: 'Écart pupillaire', valeur: ord.pd!),
                  if (ord.medecin != null) InfoRow(label: 'Médecin prescripteur', valeur: ord.medecin!),
                  if (ord.dateOrdonnance != null) InfoRow(label: 'Date de prescription',
                      valeur: '${ord.dateOrdonnance!.day.toString().padLeft(2, '0')}/'
                          '${ord.dateOrdonnance!.month.toString().padLeft(2, '0')}/'
                          '${ord.dateOrdonnance!.year}'),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _row(List<String> cells, {bool header = false}) {
    return TableRow(
      decoration: BoxDecoration(color: header ? AppColors.nude.withValues(alpha: 0.6) : Colors.transparent),
      children: cells.map((c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(c, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12,
                fontWeight: header ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.brownDark.withValues(alpha: header ? 1 : 0.85))),
      )).toList(),
    );
  }
}
