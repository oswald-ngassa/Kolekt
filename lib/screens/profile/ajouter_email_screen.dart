import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/store.dart';
import '../../theme/app_theme.dart';

class AjouterEmailScreen extends StatefulWidget {
  const AjouterEmailScreen({super.key});

  @override
  State<AjouterEmailScreen> createState() => _AjouterEmailScreenState();
}

class _AjouterEmailScreenState extends State<AjouterEmailScreen> {
  final _emailController = TextEditingController();

  void _send() {
    if (_emailController.text.trim().isEmpty) return;
    AppStore.instance.updateProfile(email: _emailController.text.trim());
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un email')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.mail_outline, size: 56, color: AppColors.primaryColor),
              const SizedBox(height: 16),
              const Text('Ajoutez votre contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text('Nous vous enverrons un code de vérification', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 20),
              Align(alignment: Alignment.centerLeft, child: const Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'votre.email@example.com')),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _send, child: const Text('Envoyer le code'))),
            ],
          ),
        ),
      ),
    );
  }
}
