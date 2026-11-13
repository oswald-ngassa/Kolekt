import 'package:flutter/material.dart';
import '../app/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_group_state.dart';
import 'account_screen.dart';

class HomeShell extends StatefulWidget {
  final String serviceName;
  const HomeShell({super.key, required this.serviceName});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;
  bool _hasActiveGroup = true; // aperçu visuel du dashboard nOVa

  void _handleCreateGroup() {
    setState(() => _hasActiveGroup = true);
  }

  void _handleChooseGroup() {
    setState(() => _hasActiveGroup = true);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _HomeTab(
        serviceName: widget.serviceName,
        hasActiveGroup: _hasActiveGroup,
        onCreateGroup: _handleCreateGroup,
        onChooseGroup: _handleChooseGroup,
      ),
      _ContributionsTab(
        hasActiveGroup: _hasActiveGroup,
        onCreateGroup: _handleCreateGroup,
        onChooseGroup: _handleChooseGroup,
      ),
      AccountScreen(
        hasActiveGroup: _hasActiveGroup,
        onCreateGroup: _handleCreateGroup,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.payments_outlined), label: 'Contributions'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'My account'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String serviceName;
  final bool hasActiveGroup;
  final VoidCallback onCreateGroup;
  final VoidCallback onChooseGroup;

  const _HomeTab({
    required this.serviceName,
    required this.hasActiveGroup,
    required this.onCreateGroup,
    required this.onChooseGroup,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      serviceName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Icon(Icons.expand_more, size: 20),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.settings),
                ),
              ],
            ),
          ),
          Expanded(
            child: hasActiveGroup
                ? _DashboardBody(serviceName: serviceName)
                : EmptyGroupState(
                    onCreateGroup: onCreateGroup,
                    onChooseGroup: onChooseGroup,
                  ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final String serviceName;

  const _DashboardBody({required this.serviceName});

  @override
  Widget build(BuildContext context) {
    final summaryCards = [
      _MetricTile(
        label: 'Monthly contribution',
        value: '12,500 FCFA',
        color: AppColors.primaryColor,
        icon: Icons.savings_rounded,
      ),
      _MetricTile(
        label: 'Current pot',
        value: '320,000 FCFA',
        color: Colors.green,
        icon: Icons.account_balance_wallet_rounded,
      ),
      _MetricTile(
        label: 'Members',
        value: '8 / 12',
        color: Colors.purple,
        icon: Icons.groups_rounded,
      ),
    ];

    final activities = [
      _ActivityRow(
          label: 'Contribution received', value: '+35,000 FCFA', time: '08:45'),
      _ActivityRow(label: 'Next turn', value: 'M. Nanga', time: 'Tomorrow'),
      _ActivityRow(label: 'New member', value: 'Marie joined', time: 'Monday'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B2A4D), Color(0xFF0F172A)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active group',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                serviceName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '12 contributions this month',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRoutes.payment),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('New contribution'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.groupDetails),
                  icon: const Icon(Icons.groups_rounded),
                  label: const Text('View group details'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 0.9,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: summaryCards,
        ),
        const SizedBox(height: 20),
        const Text(
          'Upcoming sessions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              _SessionRow(
                  title: 'Tontine 1',
                  subtitle: 'Friday · 18h30',
                  badge: 'Due soon'),
              Divider(color: AppColors.inputBorder),
              _SessionRow(
                  title: 'Member payout',
                  subtitle: 'Sunday · 15h00',
                  badge: 'Planned'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Recent activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: activities
                .map((activity) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            activity.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            activity.value,
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            activity.time,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;

  const _SessionRow({
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: AppColors.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow {
  final String label;
  final String value;
  final String time;

  const _ActivityRow({
    required this.label,
    required this.value,
    required this.time,
  });
}

class _ContributionsTab extends StatelessWidget {
  final bool hasActiveGroup;
  final VoidCallback onCreateGroup;
  final VoidCallback onChooseGroup;

  const _ContributionsTab({
    required this.hasActiveGroup,
    required this.onCreateGroup,
    required this.onChooseGroup,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Contributions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.settings),
                ),
              ],
            ),
          ),
          Expanded(
            child: hasActiveGroup
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      const _ContributionCard(
                        title: 'This month',
                        amount: '12,500 FCFA',
                        status: 'Confirmed',
                      ),
                      const _ContributionCard(
                        title: 'Next cycle',
                        amount: '15,000 FCFA',
                        status: 'Pending',
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRoutes.payment),
                        icon: const Icon(Icons.payments_rounded),
                        label: const Text('Pay with Campay'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRoutes.transactionHistory),
                        icon: const Icon(Icons.history_rounded),
                        label: const Text('See all payments'),
                      ),
                    ],
                  )
                : EmptyGroupState(
                    onCreateGroup: onCreateGroup,
                    onChooseGroup: onChooseGroup,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  final String title;
  final String amount;
  final String status;

  const _ContributionCard({
    required this.title,
    required this.amount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
