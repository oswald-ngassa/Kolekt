import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class ModifierProfilScreen extends StatefulWidget {
  const ModifierProfilScreen({super.key});

  @override
  State<ModifierProfilScreen> createState() => _ModifierProfilScreenState();
}

class _ModifierProfilScreenState extends State<ModifierProfilScreen> {
  late final _nameController = TextEditingController(text: AppStore.instance.userName ?? '');
  late final _villeController = TextEditingController(text: AppStore.instance.userVille ?? '');
  late final _paysController = TextEditingController(text: AppStore.instance.userPays ?? '');
  late final _regionController = TextEditingController(text: AppStore.instance.userRegion ?? '');
  late final _lieuController = TextEditingController(text: AppStore.instance.userLieuResidence ?? '');
  late String _statutMarital = AppStore.instance.userStatutMarital ?? 'Célibataire';

  void _save() {
    AppStore.instance.updateProfile(
      name: _nameController.text.trim(),
      ville: _villeController.text.trim(),
      pays: _paysController.text.trim(),
      region: _regionController.text.trim(),
      statutMarital: _statutMarital,
      lieuResidence: _lieuController.text.trim(),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                children: [
                  MemberAvatar(name: _nameController.text, size: 84),
                  const Positioned(
                    right: 0, bottom: 0,
                    child: CircleAvatar(radius: 14, backgroundColor: AppColors.primaryColor, child: Icon(Icons.edit, size: 14, color: Colors.black)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionLabel('Informations'),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nom complet')),
            const SizedBox(height: 12),
            Text('Matricule : ${AppStore.instance.userMatricule ?? '—'}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(controller: _lieuController, decoration: const InputDecoration(labelText: 'Lieu de résidence')),
            const SizedBox(height: 12),
            TextField(controller: _regionController, decoration: const InputDecoration(labelText: 'Région')),
            const SizedBox(height: 12),
            TextField(controller: _villeController, decoration: const InputDecoration(labelText: 'Ville')),
            const SizedBox(height: 12),
            TextField(controller: _paysController, decoration: const InputDecoration(labelText: 'Pays')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _statutMarital,
              dropdownColor: AppColors.card,
              decoration: const InputDecoration(labelText: 'Statut marital'),
              items: const ['Célibataire', 'Marié(e)', 'Divorcé(e)', 'Veuf(ve)']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _statutMarital = v ?? 'Célibataire'),
            ),
            const SizedBox(height: 12),
            Text(
              "Date d'adhésion : ${AppStore.instance.memberSince != null ? '${AppStore.instance.memberSince!.day}/${AppStore.instance.memberSince!.month}/${AppStore.instance.memberSince!.year}' : '—'}",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
  }
}
