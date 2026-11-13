import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/store.dart';
import '../../data/strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> with StoreListening {
  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final org = store.activeOrg;
    final hasOrg = org != null;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
            Text(S.t('account_title'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Stack(
            children: [
              Opacity(
                opacity: hasOrg ? 1 : 0.35,
                child: IgnorePointer(
                  ignoring: !hasOrg,
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(
                            child: _GridTile(
                                icon: Icons.block,
                                label: S.t('account_sanctions'),
                                color: AppColors.error,
                                onTap: () => hasOrg
                                    ? context.push(
                                        '/organizations/${org.id}/sanctions')
                                    : null)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _GridTile(
                                icon: Icons.account_balance_rounded,
                                label: S.t('account_accounts'),
                                color: Colors.purpleAccent,
                                onTap: () => hasOrg
                                    ? context.push(
                                        '/organizations/${org.id}/comptes')
                                    : null)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _GridTile(
                                icon: Icons.groups_rounded,
                                label: S.t('account_members'),
                                color: Colors.green,
                                onTap: () => hasOrg
                                    ? context.push(
                                        '/organizations/${org.id}/members')
                                    : null)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: _GridTile(
                                icon: Icons.event_note_rounded,
                                label: S.t('account_sessions'),
                                color: AppColors.primaryColor,
                                onTap: () => hasOrg
                                    ? context.push(
                                        '/organizations/${org.id}/sessions')
                                    : null)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _GridTile(
                                icon: Icons.settings_suggest_rounded,
                                label: S.t('account_settings'),
                                color: Colors.grey,
                                onTap: () => hasOrg
                                    ? context.push(
                                        '/organizations/${org.id}/settings')
                                    : null)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _GridTile(
                                icon: Icons.bar_chart_rounded,
                                label: S.t('account_statement'),
                                color: Colors.deepPurpleAccent,
                                onTap: () => hasOrg
                                    ? context.push(
                                        '/organizations/${org.id}/statement')
                                    : null)),
                      ]),
                    ],
                  ),
                ),
              ),
              if (!hasOrg)
                Positioned.fill(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(S.t('account_unavailable'),
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 6),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(S.t('account_create_group_access'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                            onPressed: () => context.push('/organizations/new'),
                            child: Text(S.t('home_create_group'))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _ListItem(
              icon: Icons.settings_outlined,
              label: S.t('account_settings'),
              onTap: () => context.push('/settings')),
            _ListItem(
              icon: Icons.groups_outlined,
              label: 'Mes associations',
              onTap: () => context.push('/profile/organizations')),
            _ListItem(
              icon: Icons.person_outline,
              label: S.t('account_profile'),
              onTap: () => context.push('/profile')),
          _ListItem(
              icon: Icons.help_outline, label: S.t('account_help'), onTap: () {}),
          _ListItem(
              icon: Icons.share_outlined, label: S.t('account_share'), onTap: () {}),
        ],
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _GridTile(
      {required this.icon,
      required this.label,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ListItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryColor),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
