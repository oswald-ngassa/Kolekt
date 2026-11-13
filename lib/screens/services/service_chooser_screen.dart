import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/store.dart';
import '../../theme/app_theme.dart';

class ServiceChooserScreen extends StatelessWidget {
  const ServiceChooserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = AppStore.instance.userName ?? '';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.groups_rounded, color: AppColors.primaryColor),
                      SizedBox(width: 6),
                      Text('nOVa',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.textSecondary)),
                      Icon(Icons.expand_more, color: AppColors.textSecondary),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Hello, $name',
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Choose a service',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                'One account for all your spaces. You can switch anytime.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              _ServiceCard(
                title: 'nOVa Groups',
                subtitle: 'Manage your groups, contributions and tontines',
                icon: Icons.groups_rounded,
                onTap: () => context.go('/app/home'),
              ),
              const SizedBox(height: 14),
              _ServiceCard(
                title: 'nOVa Perso',
                subtitle: 'Your personal tontine',
                icon: Icons.person_rounded,
                onTap: () => context.go('/app/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ServiceCard(
      {required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.inputBorder)),
              child: Icon(icon, color: AppColors.accentColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
