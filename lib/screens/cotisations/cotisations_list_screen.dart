import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class CotisationsListScreen extends StatefulWidget {
  final Organization org;
  final bool
      embedded; // true = affiché dans l'onglet Contributions (pas d'AppBar)
  const CotisationsListScreen(
      {super.key, required this.org, this.embedded = false});

  @override
  State<CotisationsListScreen> createState() => _CotisationsListScreenState();
}

class _CotisationsListScreenState extends State<CotisationsListScreen>
    with StoreListening {
  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: Column(
        children: [
          if (!widget.embedded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    const Text('Mes tontines',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  MemberAvatar(
                      name: widget.org.membres.isNotEmpty
                          ? widget.org.membres.first.name
                          : 'U',
                      size: 36),
                ],
              ),
            ),
          Expanded(
            child: _CotisationsBody(org: widget.org),
          ),
        ],
      ),
    );

    if (widget.embedded) return body;
    return Scaffold(body: body);
  }
}

class _CotisationsBody extends StatelessWidget {
  final Organization org;
  const _CotisationsBody({required this.org});

  @override
  Widget build(BuildContext context) {
    if (org.cotisations.isEmpty) {
      return Stack(
        children: [
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Aucune cotisation pour le moment.',
            subtitle: '',
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: () =>
                  context.push('/organizations/${org.id}/cotisations/new'),
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ),
        ],
      );
    }
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount: org.cotisations.length,
          itemBuilder: (_, i) {
            final cotisation = org.cotisations[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                title: Text(cotisation.titre,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${cotisation.frequence} • ${cotisation.collecte.toStringAsFixed(0)} ${org.currency} collecté'),
                trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary),
                onTap: () => context
                    .push('/organizations/${org.id}/cotisations/${cotisation.id}'),
              ),
            );
          },
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            onPressed: () =>
                context.push('/organizations/${org.id}/cotisations/new'),
            child: const Icon(Icons.add, color: Colors.black),
          ),
        ),
      ],
    );
  }
}
