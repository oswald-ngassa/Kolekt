import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class MemberDetailScreen extends StatefulWidget {
  final Organization org;
  final Member member;
  const MemberDetailScreen(
      {super.key, required this.org, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  Future<void> _editName() async {
    final controller = TextEditingController(text: widget.member.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Modifier le nom'),
        content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Nom complet')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Enregistrer')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      setState(() => widget.member.name = newName);
    }
  }

  Future<void> _changeRole() async {
    final newRole = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Changer le rôle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Membre', 'Administrateur', 'Propriétaire']
              .map((r) => RadioListTile<String>(
                    value: r,
                    groupValue: widget.member.role,
                    title: Text(r),
                    activeColor: AppColors.primaryColor,
                    onChanged: (v) => Navigator.pop(ctx, v),
                  ))
              .toList(),
        ),
      ),
    );
    if (newRole != null) setState(() => widget.member.role = newRole);
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final canManage = AppStore.instance.canManageOrganization(widget.org);
    final isOwner = AppStore.instance.isOrganizationOwner(widget.org);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du membre'),
        actions: canManage
            ? [
                PopupMenuButton<String>(
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'remove',
                        child: Text('Retirer du groupe',
                            style: TextStyle(color: AppColors.error))),
                  ],
                  onSelected: (v) {
                    if (v == 'remove' && canManage) {
                      widget.org.membres.remove(member);
                      Navigator.pop(context);
                    }
                  },
                ),
              ]
            : [],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: MemberAvatar(name: member.name, size: 72)),
            const SizedBox(height: 12),
            Center(
                child: Text(member.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),
            if (canManage)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                      onPressed: _editName,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier')),
                  const SizedBox(width: 10),
                  if (isOwner)
                    OutlinedButton.icon(
                        onPressed: _changeRole,
                        icon: const Icon(Icons.badge_outlined, size: 16),
                        label: const Text('Changer le rôle')),
                ],
              ),
            const SizedBox(height: 24),
            CardContainer(
              child: Column(
                children: [
                  InfoRow(label: 'Code membre', value: member.id.toUpperCase()),
                  InfoRow(label: 'Rôle', value: member.role),
                  InfoRow(
                      label: 'Numéro',
                      value: member.phone.isEmpty
                          ? (member.email ?? '')
                          : member.phone),
                  if (member.email != null && member.phone.isNotEmpty)
                    InfoRow(label: 'Email', value: member.email!),
                  if (member.ville != null || member.pays != null)
                    InfoRow(
                        label: 'Localisation',
                        value: [member.ville, member.pays]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(', ')),
                  if (member.region != null)
                    InfoRow(label: 'Région', value: member.region!),
                  if (member.statutMarital != null)
                    InfoRow(
                        label: 'Statut marital', value: member.statutMarital!),
                  InfoRow(
                      label: 'Membre depuis',
                      value:
                          '${member.joinedAt.day}/${member.joinedAt.month}/${member.joinedAt.year}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
