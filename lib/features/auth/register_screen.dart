import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../theme/app_theme.dart';

/// Écran d'inscription — design luxe Esther.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).register(
          username: _usernameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      final error = ref.read(authProvider).error ?? 'Échec de l\'inscription';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Inscription'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Créer votre compte',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.brownDark,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rejoignez Esther pour accéder au catalogue, '
                  'à l\'essai virtuel et au suivi de commandes.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.brownMedium,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 32),

                // ── Nom d'utilisateur ──
                TextFormField(
                  controller: _usernameCtrl,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nom d\'utilisateur',
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        color: AppColors.brownMedium),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().length < 3)
                          ? 'Min. 3 caractères'
                          : null,
                ),
                const SizedBox(height: 16),

                // ── Email ──
                TextFormField(
                  controller: _emailCtrl,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined,
                        color: AppColors.brownMedium),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requis';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Mot de passe ──
                TextFormField(
                  controller: _passwordCtrl,
                  enabled: !isLoading,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.brownMedium),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.brownLight,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Min. 6 caractères' : null,
                ),
                const SizedBox(height: 16),

                // ── Confirmation ──
                TextFormField(
                  controller: _confirmCtrl,
                  enabled: !isLoading,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: Icon(Icons.lock_outline_rounded,
                        color: AppColors.brownMedium),
                  ),
                  validator: (v) {
                    if (v != _passwordCtrl.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // ── Bouton ──
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.cream,
                          ),
                        )
                      : const Text('Créer mon compte'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(
                    'Déjà un compte ? Se connecter',
                    style: TextStyle(
                      color: AppColors.brownMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
