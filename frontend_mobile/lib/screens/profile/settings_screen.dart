import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

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
          _buildSettingsItem(
            context,
            'Modifier le profil',
            Icons.person_outline,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
          _buildSettingsItem(
            context,
            'Changer de mot de passe',
            Icons.lock_outline,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
          ),
          const SizedBox(height: 32),
          _buildSettingsSection('Notifications'),
          _buildSettingsItem(
            context,
            'Notifications Push',
            Icons.notifications_none_outlined,
            trailing: Switch(value: true, onChanged: (v) {}, activeThumbColor: AppColors.brunMoyen),
          ),
          _buildSettingsItem(
            context,
            'Email Marketing',
            Icons.email_outlined,
            trailing: Switch(value: false, onChanged: (v) {}, activeThumbColor: AppColors.brunMoyen),
          ),
          const SizedBox(height: 32),
          _buildSettingsSection('Autre'),
          _buildSettingsItem(
            context,
            'Politique de confidentialité',
            Icons.security_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
          ),
          _buildSettingsItem(
            context,
            'Conditions d\'utilisation',
            Icons.info_outline,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen())),
          ),
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

  Widget _buildSettingsItem(BuildContext context, String title, IconData icon, {Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.brunMoyen),
      title: Text(title, style: const TextStyle(color: AppColors.brunFonce)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.brunClair),
      onTap: onTap,
    );
  }
}
