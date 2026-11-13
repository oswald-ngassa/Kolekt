import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../data/store.dart';
import '../theme/app_theme.dart';

/// À mélanger dans un State pour que l'écran se reconstruise automatiquement
/// dès qu'une donnée change ailleurs dans l'app (ex: revenir d'un écran de
/// création sans que la liste précédente ne se rafraîchisse toute seule).
mixin StoreListening<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    AppStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    AppStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(text,
          style: TextStyle(
              color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
    );
  }
}

class CardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const CardContainer(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

/// État vide générique ("No active group", "Aucune cotisation...", etc.)
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const EmptyState({
    super.key,
    this.icon = Icons.groups_rounded,
    required this.title,
    required this.subtitle,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.primaryColor),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)),
            if (primaryLabel != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: onPrimary, child: Text(primaryLabel!)),
              ),
            ],
            if (secondaryLabel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onSecondary,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: AppColors.primaryColor,
                    side: const BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: Text(secondaryLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ToggleTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
            : null,
        value: value,
        activeThumbColor: AppColors.primaryColor,
        onChanged: onChanged,
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(color: AppColors.textSecondary))),
          Expanded(
              flex: 2,
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

/// Deux ou trois onglets sous forme de "chips" (ex: Cotisations | Tontines)
class ChipTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const ChipTabs(
      {super.key,
      required this.labels,
      required this.selected,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (i) {
        final isSel = i == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSel ? AppColors.primaryColor : AppColors.inputBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(labels[i],
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSel ? Colors.black : AppColors.textSecondary)),
            ),
          ),
        );
      }),
    );
  }
}

class MemberAvatar extends StatelessWidget {
  final String name;
  final double size;
  const MemberAvatar({super.key, required this.name, this.size = 44});

  static const List<Color> _palette = [
    Color(0xFF4E8FF0), // bleu (couleur de marque)
    Color(0xFF5FB88A), // vert
    Color(0xFFD98E4A), // orange
    Color(0xFFB077E0), // violet
    Color(0xFFE0637A), // rose
    Color(0xFF5FBFC7), // turquoise
    Color(0xFFC7A15F), // doré
  ];

  Color get _color {
    if (name.trim().isEmpty) return AppColors.primaryColor;
    final hash = name.trim().toLowerCase().codeUnits.fold(0, (a, b) => a + b);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((e) => e[0])
            .join()
            .toUpperCase();
    final color = _color;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color.withValues(alpha: 0.22),
      child: Text(initials,
          style: TextStyle(fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge({super.key, required this.role});

  Color get _color {
    switch (role) {
      case 'Propriétaire':
      case 'Propriétaire légal':
        return const Color(0xFFC7A15F); // doré
      case 'Administrateur':
        return AppColors.primaryColor;
      default:
        return const Color(0xFF5FB88A); // vert (Membre)
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10)),
      child: Text(role,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class LinkShareCard extends StatelessWidget {
  final String url;
  const LinkShareCard({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Partager le lien d'invitation",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(url, style: const TextStyle(color: AppColors.primaryColor)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lien copié')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copier'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.inputBorder),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share, size: 18, color: Colors.black),
                  label: const Text('Partager'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OrganizationMatriculeCard extends StatelessWidget {
  final String organizationName;
  final String matricule;

  const OrganizationMatriculeCard({
    super.key,
    required this.organizationName,
    required this.matricule,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Matricule de l’association',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SelectableText(
            matricule.isEmpty ? 'Matricule indisponible' : matricule,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: matricule.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(
                              ClipboardData(text: matricule));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Matricule copié')),
                            );
                          }
                        },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copier'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: matricule.isEmpty
                      ? null
                      : () => SharePlus.instance.share(
                            ShareParams(
                              title: 'Rejoindre $organizationName',
                              text:
                                  'Rejoins l’association $organizationName sur Kolekt. Matricule : $matricule',
                            ),
                          ),
                  icon: const Icon(Icons.share),
                  label: const Text('Partager'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
