import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class OrgSettingsScreen extends StatelessWidget {
  final Organization org;
  const OrgSettingsScreen({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    final isOwner = AppStore.instance.isOrganizationOwner(org);
    return Scaffold(
      appBar: AppBar(title: Text(org.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!isOwner)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                    'Seul le propriétaire peut modifier les paramètres de l’association.'),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Tournois 2026',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Actif',
                        style: TextStyle(
                            color: AppColors.primaryColor, fontSize: 12)),
                  ],
                ),
                TextButton(onPressed: () {}, child: const Text('Changer')),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: const Icon(Icons.savings_outlined,
                    color: AppColors.primaryColor),
                title: const Text('Fond de caisse',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(org.fondDeCaisseActif
                    ? 'Activé'
                    : 'Fond de caisse non activé'),
                trailing:
                    Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onTap: isOwner
                    ? () =>
                        context.push('/organizations/${org.id}/fond-de-caisse')
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            const SectionLabel('Paramètres du groupe'),
            Text('Gérez les informations et options de votre organisation.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            _SettingsRow(
                icon: Icons.badge_outlined,
                label: 'Profil',
                onTap: () {},
                enabled: isOwner),
            _SettingsRow(
                icon: Icons.tune,
                label: 'Général',
                onTap: () => context.push('/organizations/${org.id}/general'),
                enabled: isOwner),
            _SettingsRow(
                icon: Icons.link,
                label: "Lien d'invitation",
                onTap: () =>
                    context.push('/organizations/${org.id}/invite-links'),
                enabled: isOwner),
            _SettingsRow(
                icon: Icons.savings,
                label: 'Prêts et épargnes',
                onTap: () =>
                    context.push('/organizations/${org.id}/prets-epargne'),
                enabled: isOwner),
            _SettingsRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Gestionnaires wallet',
                onTap: () =>
                    context.push('/organizations/${org.id}/wallet-managers'),
                enabled: isOwner),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  const _SettingsRow(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryColor),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
