import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class SanctionsScreen extends StatelessWidget {
  final Organization org;
  const SanctionsScreen({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sanctions')),
      body: SafeArea(
        child: org.activityLog.where((entry) => entry.type == 'sanction').isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: EmptyState(
                  icon: Icons.gavel_outlined,
                  title: 'Aucune sanction pour l’instant.',
                  subtitle: '',
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: org.activityLog
                    .where((entry) => entry.type == 'sanction')
                    .map((entry) => ListTile(
                          leading: const Icon(Icons.gavel_outlined,
                              color: AppColors.error),
                          title: Text(entry.text),
                          subtitle: Text(entry.date.toLocal().toString()),
                        ))
                    .toList(),
          ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Ajouter une sanction',
        onPressed: () => _addSanction(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addSanction(BuildContext context) async {
    final memberController = TextEditingController();
    final detailsController = TextEditingController();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Nouvelle sanction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: memberController,
              decoration: const InputDecoration(labelText: 'Nom du membre'),
            ),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(labelText: 'Détail'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (memberController.text.trim().isEmpty ||
                  detailsController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(dialogContext, [
                memberController.text.trim(),
                detailsController.text.trim(),
              ]);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    memberController.dispose();
    detailsController.dispose();
    if (result == null || !context.mounted) return;
    try {
      await AppStore.instance.addSanction(org, result[0], result[1]);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enregistrement impossible : $error')),
        );
      }
    }
  }
}
