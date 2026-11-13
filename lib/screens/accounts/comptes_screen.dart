import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';

class ComptesScreen extends StatelessWidget {
  final Organization org;
  const ComptesScreen({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comptes')),
      body: SafeArea(
        child: GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: org.comptes
              .map((c) => Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Solde total', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        Text('${c.solde.toStringAsFixed(0)} ${org.currency}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        const _BreakdownRow(label: 'Mobile Money'),
                        const _BreakdownRow(label: 'Espèces'),
                        const _BreakdownRow(label: 'Bank'),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  const _BreakdownRow({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const Text('0 XAF', style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
