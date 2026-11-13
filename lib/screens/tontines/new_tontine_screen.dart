import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models.dart';
import '../../data/store.dart';

class NewTontineScreen extends StatefulWidget {
  final Organization org;
  const NewTontineScreen({super.key, required this.org});

  @override
  State<NewTontineScreen> createState() => _NewTontineScreenState();
}

class _NewTontineScreenState extends State<NewTontineScreen> {
  final _libelleController = TextEditingController();
  final _descController = TextEditingController();
  final _montantController = TextEditingController();

  Future<void> _create() async {
    if (!AppStore.instance.canManageOrganization(widget.org)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Seuls le propriétaire et les administrateurs peuvent créer une tontine.')),
      );
      return;
    }
    final amount = double.tryParse(_montantController.text.trim());
    if (_libelleController.text.trim().isEmpty ||
        amount == null ||
        amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saisissez un libellé et un montant valide.'),
        ),
      );
      return;
    }
    final t = Tontine(
      id: AppStore.instance.nextId(),
      libelle: _libelleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      montantBase: amount,
      membres: List.of(widget.org.membres),
    );
    try {
      await AppStore.instance.addTontine(widget.org, t);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Création impossible : $error')),
        );
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tontine "${t.libelle}" créée')));
      context.pop();
    }
  }

  @override
  void dispose() {
    _libelleController.dispose();
    _descController.dispose();
    _montantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle tontine')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
                controller: _libelleController,
                decoration:
                    const InputDecoration(hintText: 'Libellé de la tontine *')),
            const SizedBox(height: 12),
            TextField(
                controller: _descController,
                decoration: const InputDecoration(
                    hintText: 'Description (optionnelle)')),
            const SizedBox(height: 12),
            TextField(
              controller: _montantController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  hintText: 'Montant de base par membre *'),
            ),
            const SizedBox(height: 16),
            const Text('Ciblage des membres',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(14)),
              child: const Text('Tous les membres'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: _create, child: const Text('Créer tontine')),
          ],
        ),
      ),
    );
  }
}
