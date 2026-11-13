import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../data/strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';
import '../cotisations/cotisations_list_screen.dart';
import 'assistant_tab.dart';
import 'account_tab.dart';

class HomeShell extends StatefulWidget {
  final int initialIndex;
  const HomeShell({super.key, this.initialIndex = 0});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with StoreListening {
  late int _tabIndex = widget.initialIndex;
  bool _isRefreshing = false;

  void _goCreateGroup() => context.push('/organizations/new');
  void _goChooseGroup() => context.push('/organizations/join');

  Future<void> _refreshOrganizations() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await AppStore.instance.loadOrganizations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Données actualisées.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Actualisation impossible : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _shareOrganization(
      BuildContext context, Organization org) async {
    await SharePlus.instance.share(
      ShareParams(
        title: 'Rejoindre ${org.name}',
        text:
            'Rejoins l’association ${org.name} sur Kolekt. Matricule : ${org.joinCode ?? ''}',
      ),
    );
    if (!context.mounted) return;
  }

  Future<void> _showNotifications(
      BuildContext context, Organization organization) async {
    final notifications = organization.activityLog
        .where((entry) => entry.type != 'general')
        .toList(growable: false);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text('Notifications',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: notifications.isEmpty
                    ? const Center(child: Text('Aucune notification.'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final entry = notifications[index];
                          final icon = switch (entry.type) {
                            'payment' => Icons.payments_outlined,
                            'sanction' => Icons.gavel_outlined,
                            'member' => Icons.person_add_alt_1_outlined,
                            _ => Icons.notifications_outlined,
                          };
                          return ListTile(
                            leading: Icon(icon, color: AppColors.primaryColor),
                            title: Text(entry.text),
                            subtitle: Text(_timeAgo(entry.date)),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
    await AppStore.instance.markNotificationsRead(organization);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final hasActiveOrg = store.activeOrg != null;

    final tabs = [
      _HomeTab(
          hasActiveOrg: hasActiveOrg,
          onCreateGroup: _goCreateGroup,
          onChooseGroup: _goChooseGroup,
          onShareOrganization: _shareOrganization,
          onShowNotifications: _showNotifications,
          onRefresh: _refreshOrganizations,
          isRefreshing: _isRefreshing),
      hasActiveOrg
          ? CotisationsListScreen(org: store.activeOrg!, embedded: true)
          : _ContributionsEmptyTab(
              onCreateGroup: _goCreateGroup, onChooseGroup: _goChooseGroup),
      const AccountTab(),
      const AssistantTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded), label: S.t('nav_home')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.payments_outlined),
              label: S.t('nav_contributions')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              label: S.t('nav_account')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.auto_awesome_outlined),
              label: S.t('home_assistant')),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final bool hasActiveOrg;
  final VoidCallback onCreateGroup;
  final VoidCallback onChooseGroup;
  final Future<void> Function(BuildContext, Organization) onShareOrganization;
  final Future<void> Function(BuildContext, Organization) onShowNotifications;
  final Future<void> Function() onRefresh;
  final bool isRefreshing;

  const _HomeTab(
      {required this.hasActiveOrg,
      required this.onCreateGroup,
      required this.onChooseGroup,
      required this.onShareOrganization,
      required this.onShowNotifications,
      required this.onRefresh,
      required this.isRefreshing});

  @override
  Widget build(BuildContext context) {
    final org = AppStore.instance.activeOrg;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    org?.name ?? 'Aucune association',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                if (org != null)
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () => onShowNotifications(context, org),
                    icon: Badge(
                      isLabelVisible:
                          AppStore.instance.unreadNotificationCount(org) > 0,
                      label: Text(AppStore.instance
                          .unreadNotificationCount(org)
                          .toString()),
                      child: const Icon(Icons.notifications_none_rounded),
                    ),
                  ),
                if (org != null)
                  IconButton(
                    tooltip: 'Actualiser les données',
                    onPressed: isRefreshing ? null : onRefresh,
                    icon: isRefreshing
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                  ),
                IconButton(
                  tooltip: org == null ? 'Paramètres' : 'Partager',
                  icon: Icon(org == null
                      ? Icons.settings_outlined
                      : Icons.share_outlined),
                  onPressed: org == null
                      ? () => context.push('/settings')
                      : () => onShareOrganization(context, org),
                ),
              ],
            ),
          ),
          Expanded(
            child: !hasActiveOrg
                ? EmptyState(
                    title: S.t('home_no_group'),
                    subtitle: S.t('home_choose_or_create'),
                    primaryLabel: S.t('home_create_group'),
                    onPrimary: onCreateGroup,
                    secondaryLabel: S.t('home_choose_group'),
                    onSecondary: onChooseGroup,
                  )
                : _OrgHome(org: org!),
          ),
        ],
      ),
    );
  }
}

String _timeAgo(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 1) return "À l'instant";
  if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
  if (difference.inHours < 24) return 'Il y a ${difference.inHours} h';
  return 'Il y a ${difference.inDays} j';
}

void _ignoreTabSelection(int _) {}

class _OrgHome extends StatefulWidget {
  final Organization org;
  const _OrgHome({required this.org});

  @override
  State<_OrgHome> createState() => _OrgHomeState();
}

class _OrgHomeState extends State<_OrgHome> with StoreListening {
  bool _bannerVisible = true;

  @override
  Widget build(BuildContext context) {
    final org = widget.org;

    final cotisationItems = org.cotisations
        .map((c) => _Obligation(
              title: c.titre,
              subtitle:
                  '${c.collecte.toStringAsFixed(0)} ${org.currency} collecté',
              icon: Icons.receipt_long_outlined,
              onTap: () =>
                  context.push('/organizations/${org.id}/cotisations/${c.id}'),
            ))
        .toList();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (_bannerVisible)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Icon(Icons.lock_outline,
                    color: AppColors.primaryColor, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                      'Sécurisez votre compte\n1- Définissez votre code PIN\n2- Finalisez la vérification KYC',
                      style: TextStyle(fontSize: 12)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _bannerVisible = false),
                ),
              ],
            ),
          ),
        if (org.obligationsCount > 0 || org.membres.length > 1) ...[
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Collecté',
                  value:
                      '${org.totalCollecte.toStringAsFixed(0)} ${org.currency}',
                  icon: Icons.savings_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Membres',
                  value: '${org.membres.length}',
                  icon: Icons.groups_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Text(S.t('home_quick_actions'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.receipt_long_outlined,
                label: 'Tontine',
                onTap: () =>
                    context.push('/organizations/${org.id}/cotisations/new'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.person_add_alt_1,
                label: 'Inviter',
                onTap: () => context.push('/organizations/${org.id}/members'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(S.t('home_my_obligations'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        const ChipTabs(
            labels: ['Tous'], selected: 0, onChanged: _ignoreTabSelection),
        const SizedBox(height: 16),
        if (cotisationItems.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyState(
              icon: Icons.assignment_outlined,
              title: "Aucune obligation pour l'instant.",
              subtitle: '',
            ),
          )
        else
          ...cotisationItems.map((o) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: CircleAvatar(
                      backgroundColor: AppColors.inputBg,
                      child: Icon(o.icon,
                          color: AppColors.primaryColor, size: 20)),
                  title: Text(o.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(o.subtitle),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                  onTap: o.onTap,
                ),
              )),
        if (org.activityLog.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(S.t('home_recent_activity'),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...org.activityLog.take(5).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.text, style: const TextStyle(fontSize: 13)),
                          Text(_timeAgo(a.date),
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryColor),
            const SizedBox(height: 6),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Obligation {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  _Obligation(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.onTap});
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ContributionsEmptyTab extends StatelessWidget {
  final VoidCallback onCreateGroup;
  final VoidCallback onChooseGroup;
  const _ContributionsEmptyTab(
      {required this.onCreateGroup, required this.onChooseGroup});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(S.t('home_contributions'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
          Expanded(
            child: EmptyState(
              title: S.t('home_no_group'),
              subtitle: S.t('home_choose_or_create'),
              primaryLabel: S.t('home_create_group'),
              onPrimary: onCreateGroup,
              secondaryLabel: S.t('home_choose_group'),
              onSecondary: onChooseGroup,
            ),
          ),
        ],
      ),
    );
  }
}
