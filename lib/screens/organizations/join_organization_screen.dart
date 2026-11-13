import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/store.dart';
import '../../theme/app_theme.dart';

class JoinOrganizationScreen extends StatefulWidget {
  const JoinOrganizationScreen({super.key});

  @override
  State<JoinOrganizationScreen> createState() => _JoinOrganizationScreenState();
}

class _JoinOrganizationScreenState extends State<JoinOrganizationScreen> {
  final _codeController = TextEditingController();
  bool _isJoining = false;
  String? _error;

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _isJoining) return;

    setState(() {
      _isJoining = true;
      _error = null;
    });
    try {
      await AppStore.instance.joinOrganizationByCode(code);
      if (mounted) context.go('/app/home');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        final message = error.toString();
        _error = message.contains('Invalid join code')
            ? 'Ce matricule d’association est invalide.'
            : message.contains('Already a member')
                ? 'Vous êtes déjà membre de cette association.'
                : 'Impossible de rejoindre l’association. Vérifiez le matricule et votre connexion.';
      });
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rejoindre une association')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.group_add_outlined,
                size: 48, color: AppColors.primaryColor),
            const SizedBox(height: 20),
            const Text(
              'Saisissez le matricule envoyé par le propriétaire.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _join(),
              decoration: InputDecoration(
                labelText: 'Matricule de l’association',
                hintText: 'KOL-XXXXXXXX',
                prefixIcon: const Icon(Icons.badge_outlined),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _isJoining ? null : _join,
              icon: _isJoining
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(_isJoining ? 'Adhésion en cours…' : 'Rejoindre'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
