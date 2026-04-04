import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Changer de mot de passe', style: TextStyle(color: AppColors.brunFonce)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brunMoyen),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mot de passe actuel',
                prefixIcon: Icon(Icons.lock_outline, color: AppColors.brunClair),
              ),
            ),
            const SizedBox(height: 20),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                prefixIcon: Icon(Icons.lock_reset, color: AppColors.brunClair),
              ),
            ),
            const SizedBox(height: 20),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmer le nouveau mot de passe',
                prefixIcon: Icon(Icons.check_circle_outline, color: AppColors.brunClair),
              ),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mot de passe mis à jour')),
                );
              },
              child: const Text('Mettre à jour le mot de passe'),
            ),
          ],
        ),
      ),
    );
  }
}
