import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres', style: TextStyle(color: AppColors.brunFonce)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSettingsSection('Compte'),
          _buildSettingsItem('Modifier le profil', Icons.person_outline),
          _buildSettingsItem('Changer de mot de passe', Icons.lock_outline),
          const SizedBox(height: 32),
          _buildSettingsSection('Notifications'),
          _buildSettingsItem('Notifications Push', Icons.notifications_none_outlined, trailing: Switch(value: true, onChanged: (v) {}, activeThumbColor: AppColors.brunMoyen)),
          _buildSettingsItem('Email Marketing', Icons.email_outlined, trailing: Switch(value: false, onChanged: (v) {}, activeThumbColor: AppColors.brunMoyen)),
          const SizedBox(height: 32),
          _buildSettingsSection('Autre'),
          _buildSettingsItem('Politique de confidentialité', Icons.security_outlined),
          _buildSettingsItem('Conditions d\'utilisation', Icons.info_outline),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(color: AppColors.brunClair, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildSettingsItem(String title, IconData icon, {Widget? trailing}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.brunMoyen),
      title: Text(title, style: const TextStyle(color: AppColors.brunFonce)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.brunClair),
      onTap: () {},
    );
  }
}
