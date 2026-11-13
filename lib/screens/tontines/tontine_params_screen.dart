import 'package:flutter/material.dart';
import '../../data/store.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class TontineParamsScreen extends StatefulWidget {
  final Organization org;
  final Tontine tontine;
  const TontineParamsScreen(
      {super.key, required this.org, required this.tontine});

  @override
  State<TontineParamsScreen> createState() => _TontineParamsScreenState();
}

class _TontineParamsScreenState extends State<TontineParamsScreen> {
  bool get _canManage => AppStore.instance.canManageOrganization(widget.org);

  Future<void> _addMember() async {
    final eligible = widget.org.membres
        .where((member) =>
            !widget.tontine.membres.any((item) => item.id == member.id))
        .toList(growable: false);
    if (eligible.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tous les membres sont déjà dans cette tontine.')),
      );
      return;
    }
    final member = await showModalBottomSheet<Member>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Ajouter un membre',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...eligible.map((item) => ListTile(
                  title: Text(item.name),
                  subtitle: Text(item.phone),
                  onTap: () => Navigator.pop(sheetContext, item),
                )),
          ],
        ),
      ),
    );
    if (!mounted || member == null) return;
    try {
      await AppStore.instance
          .addTontineMember(widget.org, widget.tontine, member);
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ajout impossible : $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tontine;
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres tontine')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CardContainer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t.libelle,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Montant de base : ${t.montantBase.toStringAsFixed(0)}',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Membres & ordre de passage',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                if (_canManage)
                  TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.sort, size: 18),
                      label: const Text('Ordonner')),
              ],
            ),
            const SizedBox(height: 8),
            if (_canManage)
              OutlinedButton.icon(
                onPressed: _addMember,
                icon: const Icon(Icons.person_add_alt, size: 18),
                label: const Text('Ajouter un membre'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.primaryColor,
                  side: const BorderSide(color: AppColors.primaryColor),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Pas encore bénéfic...',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                SizedBox(width: 14),
                Text('Déjà bénéficié (0)',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            ...t.membres.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: MemberAvatar(name: m.name),
                    title: Text(m.phone),
                    subtitle: Text('${t.montantBase.toStringAsFixed(0)} • #1'),
                    trailing: _canManage
                        ? PopupMenuButton<String>(
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                  value: 'occ',
                                  child: Text('Ajouter une occurrence')),
                              PopupMenuItem(
                                  value: 'benef',
                                  child: Text('Marquer comme déjà bénéficié')),
                              PopupMenuItem(
                                  value: 'del', child: Text('Supprimer')),
                            ],
                            onSelected: (action) async {
                              if (action == 'benef') {
                                if (!t.beneficiaires
                                    .any((item) => item.id == m.id)) {
                                  t.beneficiaires.add(m);
                                  await AppStore.instance
                                      .persistOrganization(widget.org);
                                }
                              } else if (action == 'del') {
                                await AppStore.instance
                                    .removeTontineMember(widget.org, t, m);
                              }
                              if (mounted) setState(() {});
                            },
                          )
                        : null,
                  ),
                )),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {}, child: const Text('Créer un round')),
          ],
        ),
      ),
    );
  }
}
