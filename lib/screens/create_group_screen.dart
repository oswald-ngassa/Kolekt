import 'package:flutter/material.dart';
import '../app/app_router.dart';
import '../theme/app_theme.dart';

class CreateGroupScreen extends StatelessWidget {
  const CreateGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a group'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Start a new tontine',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fill in the basics to launch your group and invite members.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            const _FieldLabel('Group name'),
            const TextField(
              decoration: InputDecoration(hintText: 'e.g. Team nOVa'),
            ),
            const SizedBox(height: 18),
            const _FieldLabel('Contribution amount'),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: '5000 FCFA'),
            ),
            const SizedBox(height: 18),
            const _FieldLabel('Cycle duration'),
            const TextField(
              decoration: InputDecoration(hintText: 'Monthly'),
            ),
            const SizedBox(height: 18),
            const _FieldLabel('Description'),
            const TextField(
              maxLines: 4,
              decoration:
                  InputDecoration(hintText: 'What is this group about?'),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.homeShell,
                (route) => false,
                arguments: {'serviceName': 'nOVa Groups'},
              ),
              child: const Text('Create the group'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
