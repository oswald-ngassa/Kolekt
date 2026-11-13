import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyGroupState extends StatelessWidget {
  final VoidCallback? onCreateGroup;
  final VoidCallback? onChooseGroup;

  const EmptyGroupState({
    super.key,
    this.onCreateGroup,
    this.onChooseGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_rounded,
                size: 56, color: AppColors.primaryColor),
            const SizedBox(height: 20),
            const Text('No active group',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              'Create a group or select one to use the nOVa space.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onCreateGroup,
                child: const Text('Create a group'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onChooseGroup,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: AppColors.primaryColor,
                  side: const BorderSide(color: AppColors.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: const Text('Choose a group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
