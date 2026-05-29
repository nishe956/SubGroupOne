import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';

/// Écran de connexion — design luxe Esther.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          _usernameCtrl.text.trim(),
          _passwordCtrl.text,
        );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      final error = ref.read(authProvider).error ?? 'Identifiants incorrects';
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FadeTransition(
              opacity: _fade,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Logo ──
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.nude,
                        border: Border.all(
                          color: AppColors.brownLight.withValues(alpha: 0.55),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brownDark.withValues(alpha: 0.10),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.visibility_rounded,
                        size: 40,
                        color: AppColors.brownMedium,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Esther',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                                color: AppColors.brownDark,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connectez-vous pour continuer',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.brownMedium,
                          ),
                    ),
                    const SizedBox(height: 40),

                    // ── Username ──
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
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Password ──
                    TextFormField(
                      controller: _passwordCtrl,
                      enabled: !isLoading,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
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
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 4) ? 'Min. 4 caractères' : null,
                    ),
                    const SizedBox(height: 32),

                    // ── Bouton connexion ──
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
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
                            : const Text('Se connecter'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Créer un compte ──
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                      child: Text(
                        'Créer un compte',
                        style: TextStyle(
                          color: AppColors.brownMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Continuer en invité ──
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              ref.read(authProvider.notifier).continueAsGuest();
                              Navigator.of(context).pop();
                            },
                      child: Text(
                        'Continuer sans compte',
                        style: TextStyle(
                          color: AppColors.brownLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
