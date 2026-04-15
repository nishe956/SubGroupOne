import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../features/admin/admin_providers.dart';
import '../../features/products/products_providers.dart';
import '../../features/products/product.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final Product? productToEdit;
  const AddProductScreen({super.key, this.productToEdit});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  File? _image;
  bool _isSubmitting = false;

  late final TextEditingController _nomController;
  late final TextEditingController _marqueController;
  late final TextEditingController _prixController;
  late final TextEditingController _couleurController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _stockController;

  String _forme = 'ronde';
  String _genre = 'unisexe';

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nomController = TextEditingController(text: p?.name ?? '');
    _marqueController = TextEditingController(text: p?.reference ?? '');
    _prixController = TextEditingController(text: p != null ? p.priceEur.toString() : '');
    // Couleur and stock are not directly perfectly mapped in Product model currently, leaving empty if edit but typically would prefill.
    _couleurController = TextEditingController(); 
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _stockController = TextEditingController();
    
    if (p != null) {
      if (['ronde', 'carree', 'ovale', 'rectangulaire'].contains(p.category)) {
        _forme = p.category;
      }
      if (['homme', 'femme', 'unisexe'].contains(p.gender.toLowerCase())) {
        _genre = p.gender.toLowerCase();
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _marqueController.dispose();
    _prixController.dispose();
    _couleurController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);

    try {
      final data = <String, dynamic>{
        'nom': _nomController.text.trim(),
        'marque': _marqueController.text.trim(),
        'prix': double.tryParse(_prixController.text.trim()) ?? 0.0,
        'forme': _forme,
        'genre': _genre,
        'couleur': _couleurController.text.trim(),
        'description': _descriptionController.text.trim(),
        'stock': int.tryParse(_stockController.text.trim()) ?? 0,
        'disponible': 'true',
      };

      if (_image != null) {
        data['image'] = await MultipartFile.fromFile(_image!.path);
      }
      
      if (widget.productToEdit != null) {
        await ref.read(adminServiceProvider).updateProduct(int.parse(widget.productToEdit!.id), data);
      } else {
        await ref.read(adminServiceProvider).addProduct(data);
      }
      
      if (mounted) {
        ref.invalidate(productsCatalogProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.productToEdit != null ? 'Produit modifié avec succès !' : 'Produit ajouté avec succès !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier Produit' : 'Nouveau Produit', style: const TextStyle(color: AppColors.brunFonce)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 32),
              _buildTextField(_nomController, 'Nom du modèle', Icons.badge_outlined),
              _buildTextField(_marqueController, 'Marque', Icons.branding_watermark_outlined),
              Row(
                children: [
                   Expanded(child: _buildTextField(_prixController, 'Prix (€)', Icons.euro, keyboardType: TextInputType.number)),
                   const SizedBox(width: 16),
                   Expanded(child: _buildTextField(_stockController, 'Stock', Icons.inventory, keyboardType: TextInputType.number)),
                ],
              ),
              _buildDropdownForm('Forme', _forme, ['ronde', 'carree', 'ovale', 'rectangulaire'], (val) => setState(() => _forme = val!)),
              _buildDropdownForm('Genre', _genre, ['homme', 'femme', 'unisexe'], (val) => setState(() => _genre = val!)),
              _buildTextField(_couleurController, 'Couleur', Icons.palette_outlined),
              _buildTextField(_descriptionController, 'Description', Icons.description_outlined, maxLines: 3),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brownDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enregistrer le Produit', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.brownLight.withValues(alpha: 0.3)),
        ),
        child: _image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(_image!, fit: BoxFit.cover),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.brownMedium),
                const SizedBox(height: 12),
                const Text('Ajouter une photo', style: TextStyle(color: AppColors.brownMedium)),
              ],
            ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.brownLight),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
        validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
      ),
    );
  }

  Widget _buildDropdownForm(String label, String value, List<String> options, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.category_outlined, color: AppColors.brownLight),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
        items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt.toUpperCase()))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
