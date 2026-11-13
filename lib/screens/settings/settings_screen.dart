import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/store.dart';
import '../../data/strings.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _logout() async {
    await AuthService().signOut();
    AppStore.instance.logout();
    if (mounted) context.go('/sign-in');
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(S.t('settings_delete')),
        content: Text(S.t('settings_delete_confirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(S.t('settings_cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(S.t('settings_delete_action'),
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok == true) {
      try {
        await AppStore.instance.deleteSupabaseAccount();
        await AuthService().signOut();
        if (mounted) context.go('/sign-in');
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Suppression impossible : $error')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return Scaffold(
      appBar: AppBar(title: Text(S.t('settings_title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(S.t('settings_language'),
              style: TextStyle(
                  color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _RadioTile(
            label: 'Français',
            selected: store.language == AppLanguage.fr,
            onTap: () => setState(() => store.setLanguage(AppLanguage.fr)),
          ),
          _RadioTile(
            label: 'English',
            selected: store.language == AppLanguage.en,
            onTap: () => setState(() => store.setLanguage(AppLanguage.en)),
          ),
          const SizedBox(height: 24),
          Text(S.t('settings_theme'),
              style: TextStyle(
                  color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _RadioTile(
            label: S.t('settings_light'),
            selected: store.themeMode == ThemeMode.light,
            onTap: () => setState(() => store.setThemeMode(ThemeMode.light)),
          ),
          _RadioTile(
            label: S.t('settings_dark'),
            selected: store.themeMode == ThemeMode.dark,
            onTap: () => setState(() => store.setThemeMode(ThemeMode.dark)),
          ),
          const SizedBox(height: 24),
          Text(S.t('settings_account'),
              style: TextStyle(
                  color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(S.t('settings_delete'),
                  style: const TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.bold)),
              onTap: _confirmDelete,
            ),
          ),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: Text(S.t('settings_logout'),
                style: const TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RadioTile(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
          color: AppColors.inputBg, borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Icon(selected ? Icons.check_circle : Icons.circle_outlined,
            color: selected ? AppColors.primaryColor : AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
