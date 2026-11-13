import 'package:flutter/material.dart';
import '../../data/store.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class GeneralScreen extends StatefulWidget {
  final Organization org;
  const GeneralScreen({super.key, required this.org});

  @override
  State<GeneralScreen> createState() => _GeneralScreenState();
}

class _GeneralScreenState extends State<GeneralScreen> {
  bool _edited = false;

  @override
  Widget build(BuildContext context) {
    final org = widget.org;
    final canEdit = AppStore.instance.isOrganizationOwner(org);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Général'),
        actions: _edited && canEdit
            ? [
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _edited = false)),
                IconButton(
                  icon: const Icon(Icons.check, color: AppColors.primaryColor),
                  onPressed: () async {
                    await AppStore.instance.persistOrganization(widget.org);
                    if (mounted) setState(() => _edited = false);
                  },
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!canEdit)
              const Text(
                  'Seul le propriétaire peut modifier les paramètres de l’association.'),
            const SectionLabel('Paiements'),
            ToggleTile(
              title: 'Autoriser paiement en ligne',
              subtitle:
                  "Désactive pour les organisations hors zone XAF (ex. USA, Canada). Seuls espèces et paiement Zello/banque restent disponibles.",
              value: org.paiementEnLigne,
              onChanged: (v) {
                if (!canEdit) return;
                setState(() {
                  org.paiementEnLigne = v;
                  _edited = true;
                });
              },
            ),
            ToggleTile(
              title: 'Payer avec les frais de retraits',
              subtitle:
                  'Les paiements en ligne incluent les frais de retrait.',
              value: org.payerAvecFrais,
              onChanged: (v) {
                if (!canEdit) return;
                setState(() {
                  org.payerAvecFrais = v;
                  _edited = true;
                });
              },
            ),
            const SizedBox(height: 8),
            Text('Paiement hors ligne',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: 'Banque / virement',
              dropdownColor: AppColors.card,
              items: const ['Banque / virement', 'Espèces', 'Mobile Money']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: canEdit ? (_) => setState(() => _edited = true) : null,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(hintText: 'Libellé affiché'),
              enabled: canEdit,
              onChanged: canEdit ? (_) => setState(() => _edited = true) : null,
            ),
          ],
        ),
      ),
    );
  }
}
