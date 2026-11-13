import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class MonProfilScreen extends StatelessWidget {
  const MonProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil'), actions: [
        IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/profile/edit')),
      ]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: MemberAvatar(name: store.userName ?? '?', size: 72)),
            const SizedBox(height: 10),
            Center(child: Text(store.userName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
            CardContainer(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.email_outlined, color: AppColors.primaryColor),
                    title: Text(store.userEmail ?? 'Non renseigné'),
                    trailing: store.userEmail == null
                        ? TextButton(onPressed: () => context.push('/profile/add-email'), child: const Text('Ajouter'))
                        : null,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.phone_outlined, color: AppColors.primaryColor),
                    title: Text(store.userPhone ?? 'Non renseigné'),
                  ),
                  if (store.userVille != null || store.userPays != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on_outlined, color: AppColors.primaryColor),
                      title: Text([store.userVille, store.userPays].where((e) => e != null && e.isNotEmpty).join(', ')),
                    ),
                  if (store.userRegion != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.map_outlined, color: AppColors.primaryColor),
                      title: Text(store.userRegion!),
                    ),
                  if (store.userLieuResidence != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.home_outlined, color: AppColors.primaryColor),
                      title: Text(store.userLieuResidence!),
                    ),
                  if (store.userStatutMarital != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.favorite_outline, color: AppColors.primaryColor),
                      title: Text(store.userStatutMarital!),
                    ),
                  if (store.userMatricule != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.badge_outlined, color: AppColors.primaryColor),
                      title: Text('Matricule ${store.userMatricule}'),
                    ),
                  if (store.memberSince != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primaryColor),
                      title: Text('Membre depuis le ${store.memberSince!.day}/${store.memberSince!.month}/${store.memberSince!.year}'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _showPinSheet(context),
              icon: const Icon(Icons.lock_outline, size: 18),
              label: const Text('Définir le PIN'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), foregroundColor: AppColors.textPrimary, side: BorderSide(color: AppColors.inputBorder)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push('/profile/kyc'),
              icon: const Icon(Icons.verified_user_outlined, size: 18),
              label: const Text('Mettre à jour le KYC'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), foregroundColor: AppColors.textPrimary, side: BorderSide(color: AppColors.inputBorder)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Définir un PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Saisissez le PIN que vous voulez utiliser.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            const _PinBoxes(),
            const SizedBox(height: 10),
            Text('Confirmez le nouveau PIN.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 10),
            const _PinBoxes(),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
  }
}

class _PinBoxes extends StatelessWidget {
  const _PinBoxes();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (i) => Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            height: 48,
            decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }
}
