import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class FondDeCaisseScreen extends StatefulWidget {
  final Organization org;
  const FondDeCaisseScreen({super.key, required this.org});

  @override
  State<FondDeCaisseScreen> createState() => _FondDeCaisseScreenState();
}

class _FondDeCaisseScreenState extends State<FondDeCaisseScreen> {
  bool _activating = false;
  bool _modeProgressif = false;
  final _montantController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final org = widget.org;
    final canEdit = AppStore.instance.isOrganizationOwner(org);
    return Scaffold(
      appBar: AppBar(title: const Text('Fond de caisse')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: org.fondDeCaisseActif
              ? Center(
                  child: Text(
                    'Fond de caisse activé : ${org.fondDeCaisseMontant?.toStringAsFixed(0) ?? 0} ${org.currency} / membre',
                    textAlign: TextAlign.center,
                  ),
                )
              : !canEdit
                  ? const Center(
                      child: Text(
                          'Seul le propriétaire peut configurer le fond de caisse.'),
                    )
                  : !_activating
                      ? EmptyState(
                          icon: Icons.savings_outlined,
                          title: 'Fond de caisse non activé',
                          subtitle:
                              "Le fond de caisse n'est pas configuré pour ce tournois.",
                          primaryLabel: 'Activer',
                          onPrimary: () => setState(() => _activating = true),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Activez le fond de caisse',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 6),
                            Text(
                                'Définissez le montant du fond de caisse pour ce tournois.',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                            const SizedBox(height: 16),
                            const Text('Montant par membre',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _montantController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '0'),
                            ),
                            const SizedBox(height: 12),
                            ToggleTile(
                              title: 'Mode progressif',
                              subtitle:
                                  'Montant identique pour tous les membres',
                              value: _modeProgressif,
                              onChanged: (v) =>
                                  setState(() => _modeProgressif = v),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () async {
                                setState(() {
                                  org.fondDeCaisseActif = true;
                                  org.fondDeCaisseMontant = double.tryParse(
                                          _montantController.text) ??
                                      0;
                                });
                                await AppStore.instance
                                    .persistOrganization(org);
                              },
                              child: const Text('Activer'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () =>
                                  setState(() => _activating = false),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                foregroundColor: AppColors.textPrimary,
                                side: BorderSide(color: AppColors.inputBorder),
                              ),
                              child: const Text('Annuler'),
                            ),
                          ],
                        ),
        ),
      ),
    );
  }
}
