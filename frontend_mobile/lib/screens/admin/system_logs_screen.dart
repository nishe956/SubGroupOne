import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/admin/admin_providers.dart';
import '../../../core/widgets/empty_state_widget.dart';

class SystemLogsScreen extends ConsumerWidget {
  const SystemLogsScreen({super.key});

  static const _actionColors = {
    'Création': Color(0xFF4CAF50),
    'Suppression': Color(0xFFF44336),
    'Modification': Color(0xFFFF9800),
    'Ajout': Color(0xFF2196F3),
    'Connexion': Color(0xFF9C27B0),
  };

  Color _getColor(String action) {
    for (final key in _actionColors.keys) {
      if (action.contains(key)) return _actionColors[key]!;
    }
    return AppColors.brunMoyen;
  }

  IconData _getIcon(String action) {
    if (action.contains('Création')) return Icons.person_add_outlined;
    if (action.contains('Suppression')) return Icons.delete_outline;
    if (action.contains('Modification')) return Icons.edit_outlined;
    if (action.contains('Ajout')) return Icons.add_circle_outline;
    if (action.contains('Connexion')) return Icons.login;
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(adminLogsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.brunFonce),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Logs Système', style: TextStyle(color: AppColors.brunFonce, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.brunMoyen),
            onPressed: () => ref.invalidate(adminLogsProvider),
          ),
        ],
      ),
      body: logsAsync.when(
        data: (logs) => logs.isEmpty
            ? const EmptyStateWidget(
                icon: Icons.history,
                title: 'Aucun log',
                message: 'L\'historique des actions système s\'affichera ici dès qu\'une action sera effectuée.',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final action = log['action'] ?? 'Action inconnue';
                  final color = _getColor(action);
                  final icon = _getIcon(action);
                  final details = log['details'] ?? '';
                  final userEmail = log['user_email'] ?? 'Système';
                  final rawTime = log['timestamp']?.toString() ?? '';
                  final time = rawTime.isNotEmpty
                      ? rawTime.split('.')[0].replaceAll('T', ' à ')
                      : '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(action, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                                if (details.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(details, style: const TextStyle(color: Color(0xFF555555), fontSize: 12)),
                                ],
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 11, color: Colors.grey),
                                    const SizedBox(width: 3),
                                    Expanded(child: Text(userEmail, style: const TextStyle(color: Colors.grey, fontSize: 11), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatTime(time),
                              style: const TextStyle(color: Color(0xFF888888), fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Impossible de charger les logs', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('$e', style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(adminLogsProvider),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brunMoyen),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String time) {
    if (time.isEmpty) return '';
    // Extract only date and short time
    final parts = time.split(' à ');
    if (parts.length == 2) {
      final datePart = parts[0].split('-');
      if (datePart.length == 3) {
        final timePart = parts[1].split(':');
        return '${datePart[2]}/${datePart[1]} ${timePart[0]}:${timePart[1]}';
      }
    }
    return time;
  }
}
