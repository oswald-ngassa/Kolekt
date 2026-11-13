import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class PretsEpargneScreen extends StatefulWidget {
  final Organization org;
  const PretsEpargneScreen({super.key, required this.org});

  @override
  State<PretsEpargneScreen> createState() => _PretsEpargneScreenState();
}

class _PretsEpargneScreenState extends State<PretsEpargneScreen> {
  @override
  Widget build(BuildContext context) {
    final canEdit = AppStore.instance.isOrganizationOwner(widget.org);
    return Scaffold(
      appBar: AppBar(title: const Text('Prêts et épargne')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Icon(Icons.savings_outlined,
                  size: 48, color: AppColors.primaryColor),
              const SizedBox(height: 16),
              Text(
                "Le module prêts & épargne n'est pas encore activé.\nActivez-le ici, la configuration détaillée se fera ensuite sur le tableau de bord web.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              if (!canEdit)
                const Text(
                    'Seul le propriétaire peut modifier les paramètres de l’association.'),
              ToggleTile(
                title: 'Activer prêts & épargne',
                subtitle:
                    'Tous les membres seront autorisés à épargner par défaut.',
                value: widget.org.pretsEpargneActif,
                onChanged: (v) {
                  if (!canEdit) return;
                  setState(() => widget.org.pretsEpargneActif = v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
