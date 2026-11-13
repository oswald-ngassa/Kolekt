import 'package:flutter/material.dart';
import '../app/app_router.dart';
import '../theme/app_theme.dart';

class AccountScreen extends StatelessWidget {
  final bool hasActiveGroup;
  final VoidCallback onCreateGroup;

  const AccountScreen({
    super.key,
    this.hasActiveGroup = false,
    required this.onCreateGroup,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('My account',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Stack(
            children: [
              Opacity(
                opacity: hasActiveGroup ? 1 : 0.35,
                child: IgnorePointer(
                  ignoring: !hasActiveGroup,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: _GridTile(
                                  icon: Icons.block,
                                  label: 'Your sanctions',
                                  color: AppColors.error)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _GridTile(
                                  icon: Icons.account_balance_rounded,
                                  label: 'Accounts',
                                  color: Colors.purpleAccent)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _GridTile(
                                  icon: Icons.groups_rounded,
                                  label: 'Members',
                                  color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: _GridTile(
                                  icon: Icons.meeting_room_rounded,
                                  label: 'Sessions',
                                  color: AppColors.primaryColor)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _GridTile(
                                  icon: Icons.settings_suggest_rounded,
                                  label: 'Settings',
                                  color: Colors.grey)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _GridTile(
                                  icon: Icons.bar_chart_rounded,
                                  label: 'Statement',
                                  color: Colors.deepPurpleAccent)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (!hasActiveGroup)
                Positioned.fill(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Not available',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 6),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Create a group to access these features',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: onCreateGroup,
                          child: const Text('Create a group'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _ListItem(
            icon: Icons.person_outline,
            label: 'My profile',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
          ),
          _ListItem(
            icon: Icons.receipt_long_rounded,
            label: 'Payment history',
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.transactionHistory),
          ),
          _ListItem(
            icon: Icons.group_add_rounded,
            label: 'Invite members',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.invite),
          ),
          _ListItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
          ),
          _ListItem(
            icon: Icons.help_outline,
            label: 'Help center',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
          ),
          _ListItem(
            icon: Icons.share_outlined,
            label: 'Share the app',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.invite),
          ),
        ],
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _GridTile(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryColor),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing:
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
