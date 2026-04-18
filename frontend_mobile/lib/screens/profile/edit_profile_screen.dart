import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _assuranceNomController;
  late TextEditingController _assuranceNumeroController;
  late TextEditingController _codeFamilleController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _firstNameController = TextEditingController(text: user?.firstName);
    _lastNameController = TextEditingController(text: user?.lastName);
    _phoneController = TextEditingController(text: user?.telephone);
    _addressController = TextEditingController(text: user?.adresse);
    _assuranceNomController = TextEditingController(text: user?.assuranceNom);
    _assuranceNumeroController = TextEditingController(text: user?.assuranceNumero);
    _codeFamilleController = TextEditingController(text: user?.codeFamille);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _assuranceNomController.dispose();
    _assuranceNumeroController.dispose();
    _codeFamilleController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final success = await ref.read(authProvider.notifier).updateProfile({
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'telephone': _phoneController.text,
      'adresse': _addressController.text,
      'assurance_nom': _assuranceNomController.text,
      'assurance_numero': _assuranceNumeroController.text,
      'code_famille': _codeFamilleController.text,
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil', style: TextStyle(color: AppColors.brownDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brownMedium),
      ),
      body: authState.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Informations personnelles'),
                const SizedBox(height: 16),
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Adresse'),
                  maxLines: 2,
                ),
                
                const SizedBox(height: 32),
                _buildSectionTitle('Assurance'),
                const SizedBox(height: 16),
                TextField(
                  controller: _assuranceNomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'assurance',
                    hintText: 'ex: AXA, Gras Savoye...',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _assuranceNumeroController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de police / Adhérent',
                  ),
                ),

                const SizedBox(height: 32),
                _buildSectionTitle('Réduction Famille'),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeFamilleController,
                  decoration: const InputDecoration(
                    labelText: 'Code Famille',
                    hintText: 'Partagez ce code pour -15%',
                  ),
                ),
                
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('ENREGISTRER'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.brownMedium,
      ),
    );
  }
}
