import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/admin/admin_providers.dart';

class AddAssuranceDialog extends ConsumerStatefulWidget {
  const AddAssuranceDialog({super.key});

  @override
  ConsumerState<AddAssuranceDialog> createState() => _AddAssuranceDialogState();
}

class _AddAssuranceDialogState extends ConsumerState<AddAssuranceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _contactController = TextEditingController();
  double _taux = 80;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.health_and_safety_outlined, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nouveau partenaire', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Ajout d\'une assurance partenaire', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom
                      TextFormField(
                        controller: _nomController,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est requis' : null,
                        decoration: InputDecoration(
                          labelText: 'Nom de l\'assurance *',
                          prefixIcon: const Icon(Icons.business_outlined, color: Color(0xFF1E88E5), size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF0F7FF),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5)),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
                          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
                          labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Contact
                      TextFormField(
                        controller: _contactController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Contact (email / téléphone)',
                          prefixIcon: const Icon(Icons.contact_mail_outlined, color: Color(0xFF1E88E5), size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF0F7FF),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5)),
                          labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Taux
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.percent, color: Color(0xFF1565C0), size: 18),
                                SizedBox(width: 8),
                                Expanded(child: Text('Taux de remboursement par défaut', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF333333)))),
                              ],
                            ),
                            const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    activeTrackColor: const Color(0xFF1565C0),
                                    inactiveTrackColor: const Color(0xFFBBDEFB),
                                    thumbColor: const Color(0xFF1565C0),
                                    overlayColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                                    trackHeight: 4,
                                  ),
                                  child: Slider(
                                    value: _taux,
                                    min: 0,
                                    max: 100,
                                    divisions: 20,
                                    onChanged: (v) => setState(() => _taux = v),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 58,
                                height: 42,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_taux.toInt()}%',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('0%', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text('50%', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text('100%', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE0E0E0))),
                      ),
                      child: const Text('Annuler', style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        disabledBackgroundColor: const Color(0xFF90CAF9),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(adminServiceProvider).createAssurance({
        'nom': _nomController.text.trim(),
        'contact': _contactController.text.trim(),
        'taux_couverture_defaut': _taux.toInt(),
      });
      if (mounted) {
        ref.invalidate(adminAssurancesProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Partenaire ajouté avec succès')]),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [const Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text('Erreur: $e'))]),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
