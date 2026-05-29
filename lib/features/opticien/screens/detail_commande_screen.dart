import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../models/commande_opticien.dart';
import '../providers/commandes_opticien_provider.dart';
import '../widgets/opticien_widgets.dart';

/// Écran de détail d'une commande.
/// Retourne la commande mise à jour via Navigator.pop.
class DetailCommandeScreen extends ConsumerStatefulWidget {
  const DetailCommandeScreen({super.key, required this.commande});

  final CommandeOpticien commande;

  @override
  ConsumerState<DetailCommandeScreen> createState() => _DetailCommandeScreenState();
}

class _DetailCommandeScreenState extends ConsumerState<DetailCommandeScreen> {
  late CommandeOpticien _commande;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _commande = widget.commande;
  }

  Future<void> _afficherDialogRejet() async {
    final ctrl = TextEditingController();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: AppColors.cream,
        title: const Text('Rejeter la commande',
            style: TextStyle(color: AppColors.brownDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cette action informera le client du rejet.',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Motif du rejet (optionnel)…',
                hintStyle: TextStyle(
                    color: AppColors.brownMedium.withValues(alpha: 0.6),
                    fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.brownLight)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B3A3A)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (confirme == true) {
      await _changerStatut(StatutCommande.rejetee,
          commentaire: ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
    }
    ctrl.dispose();
  }

  Future<void> _changerStatut(StatutCommande statut, {String? commentaire}) async {
    setState(() => _isProcessing = true);

    final updated = _commande.copyWith(
      statut: statut,
      commentaireRejet: commentaire,
    );

    // Synchroniser avec le backend via le provider
    await ref.read(commandesOpticienProvider.notifier).updateCommande(updated);

    if (!mounted) return;

    setState(() {
      _commande = updated;
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(statut == StatutCommande.validee
          ? '✓ Commande validée — client notifié.'
          : '✗ Commande rejetée — client notifié.'),
    ));
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final ordonnance = _commande.ordonnance;
    final assurance = _commande.assurance;
    final peutAgir = _commande.statut == StatutCommande.enAttente;

    return Scaffold(
      appBar: AppBar(
        title: Text('Commande #${_commande.id}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StatutBadge(statut: _commande.statut),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          _SectionCard(titre: 'Client', icone: Icons.person_outline_rounded, children: [
            InfoRow(label: 'Nom', valeur: _commande.nomClient, icone: Icons.badge_outlined),
            InfoRow(label: 'Contact', valeur: _commande.contactClient, icone: Icons.phone_outlined),
          ]),
          const SizedBox(height: 14),

          _SectionCard(titre: 'Monture commandée', icone: Icons.remove_red_eye_outlined, children: [
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80, height: 60,
                  child: Image.asset(_commande.imageMonture, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.nude,
                          child: const Icon(Icons.remove_red_eye_outlined, color: AppColors.brownMedium))),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_commande.nomMonture, style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.brownDark)),
                const SizedBox(height: 4),
                Text('${_commande.prixMonture.toStringAsFixed(0)} €',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16,
                        color: AppColors.brownMedium)),
              ])),
            ]),
          ]),
          const SizedBox(height: 14),

          _SectionCard(titre: 'Ordonnance', icone: Icons.document_scanner_outlined, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: double.infinity, height: 110,
                child: Image.asset(ordonnance.imageAsset, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.nude,
                        child: const Center(child: Text('Image ordonnance non disponible',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.brownMedium))))),
              ),
            ),
            const SizedBox(height: 14),
            Table(
              border: TableBorder.all(
                  color: AppColors.brownLight.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10)),
              columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)},
              children: [
                _tRow(['', 'Œil Droit (OD)', 'Œil Gauche (OG)'], header: true),
                _tRow(['Sphère', ordonnance.odSphere ?? '—', ordonnance.ogSphere ?? '—']),
                _tRow(['Cylindre', ordonnance.odCylindre ?? '—', ordonnance.ogCylindre ?? '—']),
                _tRow(['Axe', ordonnance.odAxe ?? '—', ordonnance.ogAxe ?? '—']),
                _tRow(['Addition', ordonnance.odAddition ?? '—', ordonnance.ogAddition ?? '—']),
              ],
            ),
            const SizedBox(height: 10),
            if (ordonnance.pd != null) InfoRow(label: 'PD', valeur: ordonnance.pd!),
            if (ordonnance.medecin != null) InfoRow(label: 'Médecin', valeur: ordonnance.medecin!,
                icone: Icons.local_hospital_outlined),
            if (ordonnance.dateOrdonnance != null) InfoRow(label: 'Date',
                valeur: '${ordonnance.dateOrdonnance!.day.toString().padLeft(2, '0')}/'
                    '${ordonnance.dateOrdonnance!.month.toString().padLeft(2, '0')}/'
                    '${ordonnance.dateOrdonnance!.year}',
                icone: Icons.calendar_today_outlined),
          ]),
          const SizedBox(height: 14),

          if (assurance != null) ...[
            _SectionCard(titre: 'Assurance', icone: Icons.health_and_safety_outlined, children: [
              InfoRow(label: 'Assureur', valeur: assurance.nomAssureur, icone: Icons.business_outlined),
              InfoRow(label: 'N° PEC', valeur: assurance.numeroPriseEnCharge, icone: Icons.tag_rounded),
              InfoRow(label: 'Remboursement', valeur: '${assurance.tauxRemboursement.toStringAsFixed(0)} %',
                  icone: Icons.percent_rounded),
            ]),
            const SizedBox(height: 14),
          ],

          if (_commande.commentaireRejet != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8D7DA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B3A3A).withValues(alpha: 0.3)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF8B3A3A), size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(_commande.commentaireRejet!,
                    style: const TextStyle(color: Color(0xFF8B3A3A), fontSize: 13))),
              ]),
            ),
        ],
      ),
      bottomNavigationBar: peutAgir
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _afficherDialogRejet,
                        style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF8B3A3A),
                            side: const BorderSide(color: Color(0xFF8B3A3A), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Rejeter'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isProcessing ? null : () => _changerStatut(StatutCommande.validee),
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4A7C59),
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        icon: _isProcessing
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_rounded),
                        label: const Text('Valider'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  TableRow _tRow(List<String> cells, {bool header = false}) {
    return TableRow(
      decoration: BoxDecoration(color: header ? AppColors.nude.withValues(alpha: 0.6) : Colors.transparent),
      children: cells.map((cell) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Text(cell, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12,
                fontWeight: header ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.brownDark.withValues(alpha: header ? 1.0 : 0.85))),
      )).toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.titre, required this.icone, required this.children});
  final String titre;
  final IconData icone;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brownLight.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icone, size: 18, color: AppColors.brownMedium),
          const SizedBox(width: 8),
          Text(titre, style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.brownDark)),
        ]),
        const Divider(height: 20),
        ...children,
      ]),
    );
  }
}
