import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class MesAssociationsScreen extends StatefulWidget {
  const MesAssociationsScreen({super.key});

  @override
  State<MesAssociationsScreen> createState() => _MesAssociationsScreenState();
}

class _MesAssociationsScreenState extends State<MesAssociationsScreen>
    with StoreListening {
  bool _isManager(Organization organization) {
    final role = organization.currentUserRole.toLowerCase();
    return role.contains('administrateur') || role.contains('propriétaire');
  }

  bool _isOwner(Organization organization) {
    final userId = AppStore.instance.currentAccount?.id;
    return userId != null && organization.ownerId == userId;
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.card,
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirmer'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Action impossible : $error')),
    );
  }

  Future<void> _rename(Organization organization) async {
    final controller = TextEditingController(text: organization.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Renommer l’association'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || name == organization.name) return;

    final oldName = organization.name;
    setState(() => organization.name = name);
    try {
      await AppStore.instance.persistOrganization(organization);
    } catch (error) {
      if (mounted) setState(() => organization.name = oldName);
      if (mounted) _showError(error);
    }
  }

  Future<void> _delete(Organization organization) async {
    final confirmed = await _confirm(
      'Supprimer l’association ?',
      'Cette action supprimera l’association et ses données. Elle est irréversible.',
    );
    if (!confirmed) return;
    try {
      await AppStore.instance.deleteOrganization(organization);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _leave(Organization organization) async {
    final confirmed = await _confirm(
      'Quitter l’association ?',
      'Votre accès et votre adhésion seront retirés de cette association.',
    );
    if (!confirmed) return;
    try {
      await AppStore.instance.leaveOrganization(organization);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _handleAction(
      String action, Organization organization) async {
    switch (action) {
      case 'modify':
        context.push('/organizations/${organization.id}/edit');
      case 'rename':
        await _rename(organization);
      case 'delete':
        await _delete(organization);
      case 'leave':
        await _leave(organization);
    }
  }

  Future<void> _createCotisation() async {
    final store = AppStore.instance;
    final organizations = store.organizations;
    if (organizations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune association disponible.')),
      );
      return;
    }
    final organization = organizations
            .where((item) => item.id == store.activeOrg?.id)
            .firstOrNull ??
        organizations.first;
    context.push('/organizations/${organization.id}/cotisations/new');
  }

  @override
  Widget build(BuildContext context) {
    final organizations = AppStore.instance.organizations;

    return Scaffold(
      appBar: AppBar(title: const Text('Mes associations')),
      body: organizations.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucune association pour le moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: organizations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final organization = organizations[index];
                final isOwner = _isOwner(organization);
                final canManage = _isManager(organization);
                return Card(
                  margin: EdgeInsets.zero,
                  color: AppColors.card,
                  child: ListTile(
                    leading: MemberAvatar(name: organization.name, size: 42),
                    title: Text(
                      organization.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${organization.membres.length} membre(s) · ${organization.cotisations.length} cotisation(s)',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Actions sur l’association',
                      onSelected: (action) =>
                          _handleAction(action, organization),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'modify',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.tune),
                            title: Text('Modifier'),
                          ),
                        ),
                        if (canManage)
                          const PopupMenuItem(
                            value: 'rename',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.drive_file_rename_outline),
                              title: Text('Renommer'),
                            ),
                          ),
                        if (isOwner)
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.delete_outline),
                              title: Text('Supprimer'),
                            ),
                          )
                        else
                          const PopupMenuItem(
                            value: 'leave',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.logout),
                              title: Text('Quitter'),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createCotisation,
        tooltip: 'Créer une cotisation',
        child: const Icon(Icons.add),
      ),
    );
  }
}