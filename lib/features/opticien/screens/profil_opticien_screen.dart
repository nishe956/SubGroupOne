import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../models/opticien_profil.dart';
import '../providers/auth_opticien_provider.dart';
import '../widgets/opticien_widgets.dart';
import 'opticien_login_screen.dart';

class ProfilOpticienScreen extends ConsumerWidget {
  const ProfilOpticienScreen({super.key});

  void _ouvrirEdition(BuildContext context, WidgetRef ref, OpticienProfil profil) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditionProfilSheet(
        profil: profil,
        onSaved: (p) => ref.read(authOpticienProvider.notifier).updateProfil(p),
      ),
    );
  }

  Future<void> _confirmerDeconnexion(BuildContext context, WidgetRef ref) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.cream,
        title: const Text('Se déconnecter'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B3A3A)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
    if (confirme == true) {
      ref.read(authOpticienProvider.notifier).logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const OpticienLoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(authOpticienProvider);
    if (profil == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier mon profil',
            onPressed: () => _ouvrirEdition(context, ref, profil),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.brownMedium,
                  child: Text(
                    profil.prenom.isNotEmpty ? profil.prenom[0].toUpperCase() : 'O',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.cream),
                  ),
                ),
                const SizedBox(height: 14),
                Text(profil.nomComplet,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.brownDark)),
                const SizedBox(height: 4),
                Text(profil.boutique,
                    style: TextStyle(fontSize: 13.5,
                        color: AppColors.brownMedium.withValues(alpha: 0.85))),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionProfil(titre: 'Informations personnelles', children: [
            InfoRow(label: 'Prénom', valeur: profil.prenom, icone: Icons.person_outline_rounded),
            InfoRow(label: 'Nom', valeur: profil.nom, icone: Icons.badge_outlined),
            InfoRow(label: 'E-mail', valeur: profil.email, icone: Icons.email_outlined),
            InfoRow(label: 'Téléphone', valeur: profil.telephone, icone: Icons.phone_outlined),
          ]),
          const SizedBox(height: 14),
          _SectionProfil(titre: 'Ma boutique', children: [
            InfoRow(label: 'Nom', valeur: profil.boutique, icone: Icons.storefront_outlined),
            InfoRow(label: 'Adresse', valeur: profil.adresse, icone: Icons.location_on_outlined),
          ]),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => _ouvrirEdition(context, ref, profil),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Modifier mon profil'),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _confirmerDeconnexion(context, ref),
            style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8B3A3A),
                side: const BorderSide(color: Color(0xFF8B3A3A), width: 1.2)),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}

class _SectionProfil extends StatelessWidget {
  const _SectionProfil({required this.titre, required this.children});
  final String titre;
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
        Text(titre, style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.brownDark)),
        const Divider(height: 18),
        ...children,
      ]),
    );
  }
}

class _EditionProfilSheet extends StatefulWidget {
  const _EditionProfilSheet({required this.profil, required this.onSaved});
  final OpticienProfil profil;
  final ValueChanged<OpticienProfil> onSaved;

  @override
  State<_EditionProfilSheet> createState() => _EditionProfilSheetState();
}

class _EditionProfilSheetState extends State<_EditionProfilSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late final TextEditingController _prenomCtrl;
  late final TextEditingController _nomCtrl;
  late final TextEditingController _boutiqueCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telCtrl;
  late final TextEditingController _adresseCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.profil;
    _prenomCtrl = TextEditingController(text: p.prenom);
    _nomCtrl = TextEditingController(text: p.nom);
    _boutiqueCtrl = TextEditingController(text: p.boutique);
    _emailCtrl = TextEditingController(text: p.email);
    _telCtrl = TextEditingController(text: p.telephone);
    _adresseCtrl = TextEditingController(text: p.adresse);
  }

  @override
  void dispose() {
    for (final c in [_prenomCtrl, _nomCtrl, _boutiqueCtrl, _emailCtrl, _telCtrl, _adresseCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final updated = widget.profil.copyWith(
      prenom: _prenomCtrl.text.trim(),
      nom: _nomCtrl.text.trim(),
      boutique: _boutiqueCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      telephone: _telCtrl.text.trim(),
      adresse: _adresseCtrl.text.trim(),
    );

    // Tenter la synchronisation avec le backend
    final isLoggedIn = await ApiClient.isLoggedIn();
    if (isLoggedIn) {
      try {
        await AuthService.updateProfil(data: {
          'username': '${updated.prenom} ${updated.nom}'.trim(),
          'email': updated.email,
          'telephone': updated.telephone,
          'adresse': updated.adresse,
        });
      } catch (_) {
        // Mise à jour locale même si le backend est indisponible
      }
    }

    widget.onSaved(updated);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, sc) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: sc,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: AppColors.brownLight.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 18),
                Text('Modifier mon profil',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),
                _field('Prénom *', _prenomCtrl),
                _field('Nom *', _nomCtrl),
                _field('Nom de la boutique *', _boutiqueCtrl),
                _field('E-mail *', _emailCtrl, type: TextInputType.emailAddress),
                _field('Téléphone *', _telCtrl, type: TextInputType.phone),
                _field('Adresse *', _adresseCtrl, maxLines: 2),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _isSaving ? null : _enregistrer,
                  child: _isSaving
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream))
                      : const Text('Enregistrer les modifications'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
            color: AppColors.brownDark)),
        const SizedBox(height: 6),
        TextFormField(controller: ctrl, keyboardType: type, maxLines: maxLines,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null),
      ]),
    );
  }
}
