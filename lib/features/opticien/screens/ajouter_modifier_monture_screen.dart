import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../models/monture_opticien.dart';

/// Formulaire création / édition d'une monture.
/// UI pure — résultat retourné via Navigator.pop.
class AjouterModifierMontureScreen extends StatefulWidget {
  const AjouterModifierMontureScreen({super.key, this.monture});

  final MontureOpticien? monture;

  @override
  State<AjouterModifierMontureScreen> createState() =>
      _AjouterModifierMontureScreenState();
}

class _AjouterModifierMontureScreenState
    extends State<AjouterModifierMontureScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late final TextEditingController _nomCtrl;
  late final TextEditingController _marqueCtrl;
  late final TextEditingController _prixCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _couleurCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _refCtrl;
  late String _categorie;

  bool get _isEdition => widget.monture != null;

  @override
  void initState() {
    super.initState();
    final m = widget.monture;
    _nomCtrl = TextEditingController(text: m?.nom ?? '');
    _marqueCtrl = TextEditingController(text: m?.marque ?? '');
    _prixCtrl = TextEditingController(text: m != null ? m.prix.toStringAsFixed(0) : '');
    _descCtrl = TextEditingController(text: m?.description ?? '');
    _couleurCtrl = TextEditingController(text: m?.couleur ?? '');
    _stockCtrl = TextEditingController(text: m != null ? '${m.stock}' : '');
    _refCtrl = TextEditingController(text: m?.reference ?? '');
    _categorie = m?.categorie ?? kMainGlassCategories.first;
  }

  @override
  void dispose() {
    for (final c in [_nomCtrl, _marqueCtrl, _prixCtrl, _descCtrl, _couleurCtrl, _stockCtrl, _refCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final result = MontureOpticien(
      id: widget.monture?.id ?? 'op_${DateTime.now().millisecondsSinceEpoch}',
      nom: _nomCtrl.text.trim(),
      marque: _marqueCtrl.text.trim(),
      prix: double.tryParse(_prixCtrl.text) ?? 0,
      description: _descCtrl.text.trim(),
      categorie: _categorie,
      couleur: _couleurCtrl.text.trim(),
      stock: int.tryParse(_stockCtrl.text) ?? 0,
      estActive: widget.monture?.estActive ?? true,
      imageAsset: widget.monture?.imageAsset,
      reference: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
    );

    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdition ? 'Modifier la monture' : 'Nouvelle monture')),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          children: [
            _label('Nom de la monture *'),
            const SizedBox(height: 6),
            TextFormField(controller: _nomCtrl, textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'Ex: Carrées Studio Silver'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null),
            const SizedBox(height: 16),

            _label('Marque *'),
            const SizedBox(height: 6),
            TextFormField(controller: _marqueCtrl, textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'Ex: Esther Paris'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null),
            const SizedBox(height: 16),

            _label('Prix (€) *'),
            const SizedBox(height: 6),
            TextFormField(controller: _prixCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'Ex: 450'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Prix invalide';
                  return null;
                }),
            const SizedBox(height: 16),

            _label('Catégorie *'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _categorie,
              borderRadius: BorderRadius.circular(16),
              decoration: const InputDecoration(),
              items: kMainGlassCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) { if (v != null) setState(() => _categorie = v); },
            ),
            const SizedBox(height: 16),

            _label('Couleur *'),
            const SizedBox(height: 6),
            TextFormField(controller: _couleurCtrl, textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'Ex: Or brossé'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null),
            const SizedBox(height: 16),

            _label('Stock *'),
            const SizedBox(height: 6),
            TextFormField(controller: _stockCtrl, keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'Nombre d\'unités disponibles'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
                  if (int.tryParse(v) == null) return 'Nombre entier requis';
                  return null;
                }),
            const SizedBox(height: 16),

            _label('Référence (optionnelle)'),
            const SizedBox(height: 6),
            TextFormField(controller: _refCtrl, textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'Ex: CSS-220')),
            const SizedBox(height: 16),

            _label('Description *'),
            const SizedBox(height: 6),
            TextFormField(controller: _descCtrl, maxLines: 4, textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                    hintText: 'Description détaillée…', alignLabelWithHint: true),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: FilledButton(
            onPressed: _isSaving ? null : _enregistrer,
            child: _isSaving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream))
                : Text(_isEdition ? 'Mettre à jour' : 'Enregistrer'),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brownDark));
}

// Exposer les catégories depuis opticien_data
const List<String> kMainGlassCategories = [
  'Lunettes de vue', 'Lunettes de soleil', 'Anti-lumière bleue',
  'Rondes', 'Rectangulaires', 'Carrées',
  'Œil de chat (ou Cat-eye)', 'Aviateur', 'Oversize',
];
