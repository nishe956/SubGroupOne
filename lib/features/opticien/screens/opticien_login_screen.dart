import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../providers/auth_opticien_provider.dart';
import 'opticien_shell_screen.dart';

class OpticienLoginScreen extends ConsumerStatefulWidget {
  const OpticienLoginScreen({super.key});

  @override
  ConsumerState<OpticienLoginScreen> createState() => _OpticienLoginScreenState();
}

class _OpticienLoginScreenState extends ConsumerState<OpticienLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _mdpController = TextEditingController();
  bool _mdpVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _mdpController.dispose();
    super.dispose();
  }

  Future<void> _connexion() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(authOpticienProvider.notifier).login(
          _emailController.text.trim().toLowerCase(),
          _mdpController.text,
        );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const OpticienShellScreen(),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Identifiants incorrects. Veuillez réessayer.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 56, 28, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.brownMedium,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.remove_red_eye_outlined,
                          color: AppColors.cream,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Esther Opticien',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.brownDark,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Connectez-vous à votre espace professionnel',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.brownDark.withValues(alpha: 0.6),
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Adresse e-mail',
                    hintText: 'opticien@esther.fr',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.brownMedium),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Veuillez saisir votre e-mail';
                    if (!v.contains('@')) return 'Adresse e-mail invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _mdpController,
                  obscureText: !_mdpVisible,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  onFieldSubmitted: (_) => _connexion(),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.brownMedium),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mdpVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.brownMedium,
                      ),
                      onPressed: () => setState(() => _mdpVisible = !_mdpVisible),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Veuillez saisir votre mot de passe';
                    if (v.length < 6) return 'Au moins 6 caractères requis';
                    return null;
                  },
                ),
                const SizedBox(height: 36),

                FilledButton(
                  onPressed: _isLoading ? null : _connexion,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream),
                        )
                      : const Text('Se connecter'),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.nude.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.brownLight.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16,
                          color: AppColors.brownMedium.withValues(alpha: 0.8)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Démo : opticien@esther.fr / esther2025',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.brownDark.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
