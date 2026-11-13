import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class MembersScreen extends StatefulWidget {
  final Organization org;
  const MembersScreen({super.key, required this.org});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> with StoreListening {
  String _query = '';

  bool get _canShareOrganizationCode {
    return AppStore.instance.canManageOrganization(widget.org);
  }

  List<Member> get _filtered {
    if (_query.trim().isEmpty) return widget.org.membres;
    final q = _query.toLowerCase();
    return widget.org.membres
        .where((m) =>
            m.name.toLowerCase().contains(q) ||
            m.phone.toLowerCase().contains(q) ||
            (m.email ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final org = widget.org;
    return Scaffold(
      appBar: AppBar(title: const Text('Membres')),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () async => setState(() {}),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  if (_canShareOrganizationCode) ...[
                    OrganizationMatriculeCard(
                      organizationName: org.name,
                      matricule: org.joinCode ?? '',
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                      'Gérez les membres de votre organisation • ${org.membres.length} au total',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                        hintText: 'Rechercher par nom, email ou co...',
                        prefixIcon: Icon(Icons.search)),
                  ),
                  const SizedBox(height: 12),
                  if (_filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text('Aucun membre ne correspond à "$_query".',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    ..._filtered.map((m) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            leading: MemberAvatar(name: m.name),
                            title: Text(m.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                m.phone.isEmpty ? (m.email ?? '') : m.phone),
                            trailing: RoleBadge(role: m.role),
                            onTap: () => context.push(
                                '/organizations/${org.id}/members/${m.id}'),
                          ),
                        )),
                ],
              ),
            ),
            if (_canShareOrganizationCode)
              Positioned(
                right: 20,
                bottom: 20,
                child: FloatingActionButton(
                  onPressed: () async {
                    await context.push('/organizations/${org.id}/members/new');
                    if (mounted) setState(() {});
                  },
                  child:
                      const Icon(Icons.person_add_alt_1, color: Colors.black),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
