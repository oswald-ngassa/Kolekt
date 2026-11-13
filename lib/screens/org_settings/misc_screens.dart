import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class SessionsScreen extends StatelessWidget {
  final Organization org;
  const SessionsScreen({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: const Icon(Icons.emoji_events_outlined, color: AppColors.primaryColor),
                title: const Text('Tournois 2026', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Actif', style: TextStyle(color: AppColors.primaryColor, fontSize: 12)),
                trailing: const Icon(Icons.check_circle, color: AppColors.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatementScreen extends StatelessWidget {
  final Organization org;
  const StatementScreen({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statement')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: EmptyState(
            icon: Icons.bar_chart_rounded,
            title: 'Aucune transaction pour le moment',
            subtitle: 'Les mouvements de vos comptes apparaîtront ici.',
          ),
        ),
      ),
    );
  }
}
