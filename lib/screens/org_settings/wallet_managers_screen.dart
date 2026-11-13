import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class WalletManagersScreen extends StatefulWidget {
  final Organization org;
  const WalletManagersScreen({super.key, required this.org});

  @override
  State<WalletManagersScreen> createState() => _WalletManagersScreenState();
}

class _WalletManagersScreenState extends State<WalletManagersScreen>
    with StoreListening {
  void _openAddSheet() {
    if (!AppStore.instance.isOrganizationOwner(widget.org)) return;
    String role = 'Administrateur';
    String canal = 'Email';
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ajouter un gestionnaire',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text('Recherchez un membre à ajouter comme co-gestionnaire.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 14),
              TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                      hintText: 'Rechercher un membre...',
                      prefixIcon: Icon(Icons.search))),
              const SizedBox(height: 14),
              ...widget.org.membres.map((m) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: MemberAvatar(name: m.name, size: 36),
                    title: Text(m.phone),
                    trailing: widget.org.walletManagers
                            .any((w) => w.member.id == m.id)
                        ? Text('Déjà gestionnaire',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 11))
                        : null,
                  )),
              const SizedBox(height: 10),
              const Text('Rôle sur le wallet',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        setSheetState(() => role = 'Administrateur'),
                    style: OutlinedButton.styleFrom(
                        backgroundColor: role == 'Administrateur'
                            ? AppColors.primaryColor
                            : null,
                        foregroundColor: role == 'Administrateur'
                            ? Colors.black
                            : AppColors.textPrimary),
                    child: const Text('Administrateur'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        setSheetState(() => role = 'Propriétaire légal'),
                    style: OutlinedButton.styleFrom(
                        backgroundColor: role == 'Propriétaire légal'
                            ? AppColors.primaryColor
                            : null,
                        foregroundColor: role == 'Propriétaire légal'
                            ? Colors.black
                            : AppColors.textPrimary),
                    child: const Text('Propriétaire légal'),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              const Text('Canal OTP',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setSheetState(() => canal = 'Email'),
                    style: OutlinedButton.styleFrom(
                        backgroundColor:
                            canal == 'Email' ? AppColors.primaryColor : null,
                        foregroundColor: canal == 'Email'
                            ? Colors.black
                            : AppColors.textPrimary),
                    child: const Text('Email'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setSheetState(() => canal = 'SMS'),
                    style: OutlinedButton.styleFrom(
                        backgroundColor:
                            canal == 'SMS' ? AppColors.primaryColor : null,
                        foregroundColor: canal == 'SMS'
                            ? Colors.black
                            : AppColors.textPrimary),
                    child: const Text('SMS'),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.org.membres.isEmpty
                    ? null
                    : () async {
                        await AppStore.instance.addWalletManager(
                          widget.org,
                          WalletManager(
                              member: widget.org.membres.first, role: role),
                        );
                        Navigator.pop(ctx);
                        setState(() {});
                      },
                child: const Text("Envoyer l'OTP"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final org = widget.org;
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionnaires wallet')),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                Text(
                    'Gérez qui peut administrer le compte de paiement du groupe.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 16),
                if (org.walletManagers.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                        child: Text('Aucun gestionnaire pour le moment.',
                            style: TextStyle(color: AppColors.textSecondary))),
                  )
                else
                  ...org.walletManagers.map((w) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: MemberAvatar(name: w.member.name),
                          title: Text(w.member.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(w.member.phone),
                          trailing: RoleBadge(role: w.role),
                        ),
                      )),
              ],
            ),
            if (AppStore.instance.isOrganizationOwner(org))
              Positioned(
                right: 20,
                bottom: 20,
                child: FloatingActionButton.extended(
                  onPressed: _openAddSheet,
                  icon: const Icon(Icons.person_add_alt, color: Colors.black),
                  label: const Text('Ajouter',
                      style: TextStyle(color: Colors.black)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
