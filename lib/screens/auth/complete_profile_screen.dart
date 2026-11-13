import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String name;
  final String contact; // téléphone ou email déjà vérifié
  final bool contactIsEmail;

  const CompleteProfileScreen({
    super.key,
    required this.name,
    required this.contact,
    required this.contactIsEmail,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  late final _secondContactController = TextEditingController();
  final _villeController = TextEditingController();
  final _paysController = TextEditingController(text: 'Cameroun');
  final _regionController = TextEditingController();
  final _lieuController = TextEditingController();
  String _statutMarital = 'Célibataire';

  void _finish() {
    AppStore.instance.signUp(
      name: widget.name,
      phone: widget.contactIsEmail
          ? _secondContactController.text.trim()
          : widget.contact,
      email: widget.contactIsEmail
          ? widget.contact
          : _secondContactController.text.trim(),
      password: '',
      ville: _villeController.text.trim().isEmpty
          ? null
          : _villeController.text.trim(),
      pays: _paysController.text.trim().isEmpty
          ? null
          : _paysController.text.trim(),
      region: _regionController.text.trim().isEmpty
          ? null
          : _regionController.text.trim(),
      statutMarital: _statutMarital,
      lieuResidence: _lieuController.text.trim().isEmpty
          ? null
          : _lieuController.text.trim(),
    );
    context.go('/app/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(28)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Complétez votre profil',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    'Ces informations seront affichées sur votre profil nOVa.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  const SectionLabel('Bonjour'),
                  Text(widget.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _secondContactController,
                    keyboardType: widget.contactIsEmail
                        ? TextInputType.phone
                        : TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: widget.contactIsEmail
                          ? 'Numéro de téléphone (optionnel)'
                          : 'Adresse email (optionnelle)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                              controller: _villeController,
                              decoration:
                                  const InputDecoration(hintText: 'Ville'))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: TextField(
                              controller: _paysController,
                              decoration:
                                  const InputDecoration(hintText: 'Pays'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _regionController,
                      decoration: const InputDecoration(
                          hintText: 'Région (optionnel)')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _lieuController,
                      decoration: const InputDecoration(
                          hintText: 'Lieu de résidence (optionnel)')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _statutMarital,
                    dropdownColor: AppColors.card,
                    decoration:
                        const InputDecoration(labelText: 'Statut marital'),
                    items: const [
                      'Célibataire',
                      'Marié(e)',
                      'Divorcé(e)',
                      'Veuf(ve)'
                    ]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _statutMarital = v ?? 'Célibataire'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: _finish,
                        child: const Text('Terminer mon inscription')),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        AppStore.instance.signUp(
                          name: widget.name,
                          phone: widget.contactIsEmail ? null : widget.contact,
                          email: widget.contactIsEmail ? widget.contact : null,
                          password: '',
                        );
                        context.go('/app/home');
                      },
                      child: Text("Passer pour l'instant",
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
