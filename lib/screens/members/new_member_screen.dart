import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../theme/app_theme.dart';

class NewMemberScreen extends StatefulWidget {
  final Organization org;
  const NewMemberScreen({super.key, required this.org});

  @override
  State<NewMemberScreen> createState() => _NewMemberScreenState();
}

class _NewMemberScreenState extends State<NewMemberScreen> {
  bool _byEmail = false;
  String _countryCode = '+237';
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  String _role = 'Membre';

  Future<void> _create() async {
    if (!AppStore.instance.canManageOrganization(widget.org)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Seuls le propriétaire et les administrateurs peuvent ajouter un membre.')),
      );
      return;
    }
    final contact = _byEmail
        ? _emailController.text.trim()
        : '$_countryCode${_phoneController.text.trim()}';
    if (contact.isEmpty) return;
    final m = Member(
      id: AppStore.instance.nextId(),
      name: _nameController.text.trim().isEmpty
          ? contact
          : _nameController.text.trim(),
      phone: _byEmail ? '' : contact,
      email: _byEmail ? contact : null,
      role: _role,
    );
    await AppStore.instance.addMember(widget.org, m);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${m.name} a été ajouté(e)')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = AppStore.instance.isOrganizationOwner(widget.org);
    return Scaffold(
      appBar: AppBar(title: const Text('Membres')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Créer un membre',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Ajoutez les informations du membre.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _byEmail = true),
                    icon: const Icon(Icons.email_outlined, size: 18),
                    label: const Text('Email'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _byEmail ? AppColors.primaryColor : null,
                      foregroundColor:
                          _byEmail ? Colors.black : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _byEmail = false),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Numéro'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          !_byEmail ? AppColors.primaryColor : null,
                      foregroundColor:
                          !_byEmail ? Colors.black : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_byEmail)
              TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      hintText: 'votre.email@example.com'))
            else
              Row(
                children: [
                  CountryCodePicker(
                    initialSelection: 'CM',
                    onChanged: (c) =>
                        setState(() => _countryCode = c.dialCode ?? '+237'),
                  ),
                  Expanded(
                      child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration:
                              const InputDecoration(hintText: '677 12 34 56'))),
                ],
              ),
            const SizedBox(height: 12),
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                    hintText: 'Nom complet (ex: Jean Dupont)')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              dropdownColor: AppColors.card,
              items: (isOwner
                      ? const ['Membre', 'Administrateur', 'Propriétaire']
                      : const ['Membre'])
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _role = v ?? 'Membre'),
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text("Plus d'informations",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              childrenPadding: EdgeInsets.zero,
              children: const [
                _DisabledField('Matricule (optionnel)'),
                _DisabledField('Pays'),
                _DisabledField('Statut marital'),
                _DisabledField('Date d\'adhésion'),
                _DisabledField('Ville'),
                _DisabledField('Région'),
                _DisabledField('Lieu de résidence'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.inputBorder)),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton(
                        onPressed: _create, child: const Text('Créer'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DisabledField extends StatelessWidget {
  final String hint;
  const _DisabledField(this.hint);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: TextField(
          enabled: false, decoration: InputDecoration(hintText: hint)),
    );
  }
}
