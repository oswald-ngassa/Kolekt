import 'package:flutter/material.dart';
import '../app/app_router.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

enum _Lang { fr, en }

enum _ThemeMode { light, dark }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _Lang _lang = _Lang.fr;
  _ThemeMode _themeMode = _ThemeMode.dark;

  Future<void> _handleLogout() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.authSignIn,
        (route) => false,
      );
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Supprimer le compte'),
        content: const Text(
            'Cette action est irréversible. Voulez-vous continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'La suppression du compte doit être configurée côté serveur Supabase.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionLabel('Language'),
          _RadioTile(
            label: 'Français',
            selected: _lang == _Lang.fr,
            onTap: () => setState(() => _lang = _Lang.fr),
          ),
          _RadioTile(
            label: 'English',
            selected: _lang == _Lang.en,
            onTap: () => setState(() => _lang = _Lang.en),
          ),
          const SizedBox(height: 24),
          _SectionLabel('Theme'),
          _RadioTile(
            label: 'Light',
            selected: _themeMode == _ThemeMode.light,
            onTap: () => setState(() => _themeMode = _ThemeMode.light),
          ),
          _RadioTile(
            label: 'Dark',
            selected: _themeMode == _ThemeMode.dark,
            onTap: () => setState(() => _themeMode = _ThemeMode.dark),
          ),
          const SizedBox(height: 24),
          _SectionLabel('Account'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete my account',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.bold)),
              onTap: _confirmDeleteAccount,
            ),
          ),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: AppColors.error),
            label:
                const Text('Log out', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
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
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppColors.primaryColor)
            : const Icon(Icons.circle_outlined, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
