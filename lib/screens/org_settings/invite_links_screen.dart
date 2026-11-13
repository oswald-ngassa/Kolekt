import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class InviteLinksScreen extends StatefulWidget {
  final Organization org;
  const InviteLinksScreen({super.key, required this.org});

  @override
  State<InviteLinksScreen> createState() => _InviteLinksScreenState();
}

class _InviteLinksScreenState extends State<InviteLinksScreen>
    with StoreListening {
  bool _creating = false;
  final _expirationController = TextEditingController(text: '30');
  final _maxController = TextEditingController();
  final _messageController = TextEditingController();
  String _role = 'Membre';
  bool get _isOwner => AppStore.instance.isOrganizationOwner(widget.org);

  Future<void> _create() async {
    if (!_isOwner) return;
    final link = InviteLink(
      id: AppStore.instance.nextId(),
      url: widget.org.inviteUrl,
      expirationJours: int.tryParse(_expirationController.text) ?? 30,
      maxAdhesions: int.tryParse(_maxController.text),
      role: _role,
      message: _messageController.text.trim().isEmpty
          ? null
          : _messageController.text.trim(),
    );
    await AppStore.instance.addInviteLink(widget.org, link);
    setState(() => _creating = false);
  }

  @override
  Widget build(BuildContext context) {
    final org = widget.org;
    return Scaffold(
      appBar: AppBar(title: const Text("Liens d'invitation")),
      body: SafeArea(
        child: _creating
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gérez les liens pour inviter de nouveaux membres.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 16),
                    const Text('Nouveau lien d\'invitation',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                        'Configurez la durée, les limites et le rôle du nouveau membre.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _expirationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Expiration (jours, vide = sans limite)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _maxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          hintText:
                              "Nombre max. d'adhésions (vide = illimité)"),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _role,
                      dropdownColor: AppColors.card,
                      items: const ['Membre', 'Administrateur']
                          .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (v) => setState(() => _role = v ?? 'Membre'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                            hintText: 'Message personnalisé (optionnel)')),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _creating = false),
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
                                onPressed: _create,
                                child: const Text('Créer'))),
                      ],
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    children: [
                      Text('Gérez les liens pour inviter de nouveaux membres.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 16),
                      if (org.inviteLinks.isEmpty)
                        Container(
                          decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            leading: const Icon(Icons.check_circle,
                                color: AppColors.primaryColor, size: 18),
                            title: Text(org.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(org.inviteUrl,
                                style: const TextStyle(
                                    color: AppColors.primaryColor)),
                          ),
                        )
                      else
                        ...org.inviteLinks.map((l) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(14)),
                              child: ListTile(
                                title: Text(l.actif ? 'Actif' : 'Inactif',
                                    style: TextStyle(
                                        color: l.actif
                                            ? AppColors.primaryColor
                                            : AppColors.textSecondary,
                                        fontSize: 12)),
                                subtitle: Text(l.url,
                                    style: const TextStyle(fontSize: 12)),
                                trailing: _isOwner
                                    ? PopupMenuButton<String>(
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                              value: 'off',
                                              child: Text('Désactiver')),
                                          PopupMenuItem(
                                              value: 'del',
                                              child: Text('Supprimer',
                                                  style: TextStyle(
                                                      color: AppColors.error))),
                                        ],
                                        onSelected: (v) => setState(() {
                                          if (v == 'off') l.actif = false;
                                          if (v == 'del')
                                            org.inviteLinks.remove(l);
                                        }),
                                      )
                                    : null,
                              ),
                            )),
                    ],
                  ),
                  if (_isOwner)
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: FloatingActionButton(
                        onPressed: () => setState(() => _creating = true),
                        child: const Icon(Icons.add, color: Colors.black),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
