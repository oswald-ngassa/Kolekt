import 'package:flutter/material.dart';
import '../app/app_router.dart';
import '../data/store.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _nameController = TextEditingController();
  final _villeController = TextEditingController();
  final _paysController = TextEditingController(text: 'Cameroun');
  final _regionController = TextEditingController();
  final _lieuController = TextEditingController();
  String _statutMarital = 'Célibataire';
  bool _loading = false;

  Future<void> _handleContinue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _loading = true);
    final user = AuthService().currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    await UserService().createUser(
      user.id,
      name: name,
      phone: user.phone,
      email: user.email,
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
    AppStore.instance.syncSupabaseUser(user, profile: {
      'name': name,
      'phone': user.phone,
      'email': user.email,
      'ville': _villeController.text.trim(),
      'pays': _paysController.text.trim(),
      'region': _regionController.text.trim(),
      'statutMarital': _statutMarital,
      'lieuResidence': _lieuController.text.trim(),
    });

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.homeShell,
        (route) => false,
        arguments: {'name': name},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Quel est votre nom ?',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Nom complet'),
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
                        .map((value) =>
                            DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _statutMarital = value ?? 'Célibataire'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleContinue,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black),
                            )
                          : const Text('Continuer'),
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
