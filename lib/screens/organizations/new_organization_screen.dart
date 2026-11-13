import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../data/strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class NewOrganizationScreen extends StatefulWidget {
  final Organization? organization;

  const NewOrganizationScreen({super.key, this.organization});

  @override
  State<NewOrganizationScreen> createState() => _NewOrganizationScreenState();
}

class _NewOrganizationScreenState extends State<NewOrganizationScreen>
    with StoreListening {
  int _step = 0;
  final _nameController = TextEditingController();
  final _acronymController = TextEditingController();
  final _referralController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _currency = 'XAF';
  bool _fondDeCaisse = false;

  dynamic _createdOrg;
  bool get _isEditing => widget.organization != null;

  @override
  void initState() {
    super.initState();
    final org = widget.organization;
    if (org == null) return;
    _nameController.text = org.name;
    _acronymController.text = org.acronym ?? '';
    _referralController.text = org.referralCode ?? '';
    _descriptionController.text = org.description ?? '';
    _currency = org.currency;
    _fondDeCaisse = org.fondDeCaisseActif;
  }

  Future<void> _next() async {
    if (_step == 0) {
      if (_nameController.text.trim().isEmpty) return;
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (_isEditing) {
        final org = widget.organization!;
        org.name = _nameController.text.trim();
        org.acronym = _acronymController.text.trim().isEmpty
            ? null
            : _acronymController.text.trim();
        org.referralCode = _referralController.text.trim().isEmpty
            ? null
            : _referralController.text.trim();
        org.description = _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim();
        org.currency = _currency;
        org.fondDeCaisseActif = _fondDeCaisse;
        await AppStore.instance.persistOrganization(org);
        if (mounted) context.pop();
        return;
      }

      _createdOrg = await AppStore.instance.createOrganization(
        name: _nameController.text.trim(),
        acronym: _acronymController.text.trim().isEmpty
            ? null
            : _acronymController.text.trim(),
        referralCode: _referralController.text.trim().isEmpty
            ? null
            : _referralController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        currency: _currency,
      );
      _createdOrg.fondDeCaisseActif = _fondDeCaisse;
      await AppStore.instance.persistOrganization(_createdOrg);
      setState(() => _step = 2);
    } else {
      context.go('/app/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      S.t('org_new_title'),
      S.t('org_new_title'),
      S.t('org_invitation')
    ];
    return Scaffold(
      appBar: _step < 2
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: () =>
                    _step == 0 ? context.pop() : setState(() => _step--),
              ),
              title: Text(titles[_step]),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _step == 0
              ? _StepInfo(
                  nameController: _nameController,
                  acronymController: _acronymController,
                  referralController: _referralController,
                  descriptionController: _descriptionController,
                  currency: _currency,
                  onCurrencyChanged: (c) => setState(() => _currency = c),
                  onContinue: _next,
                )
              : _step == 1
                  ? _StepParams(
                      fondDeCaisse: _fondDeCaisse,
                      isEditing: _isEditing,
                      onFondDeCaisseChanged: (v) =>
                          setState(() => _fondDeCaisse = v),
                      onBack: () => setState(() => _step = 0),
                      onCreate: _next,
                    )
                  : _StepDone(org: _createdOrg, onAccess: _next),
        ),
      ),
    );
  }
}

class _StepInfo extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController acronymController;
  final TextEditingController referralController;
  final TextEditingController descriptionController;
  final String currency;
  final ValueChanged<String> onCurrencyChanged;
  final VoidCallback onContinue;

  const _StepInfo({
    required this.nameController,
    required this.acronymController,
    required this.referralController,
    required this.descriptionController,
    required this.currency,
    required this.onCurrencyChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.t('org_step_info'),
            style: TextStyle(
                color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(hintText: S.t('org_name_hint')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: acronymController,
                decoration: InputDecoration(hintText: S.t('org_acronym_hint')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: referralController,
                decoration: InputDecoration(hintText: S.t('org_referral_hint')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration:
                    InputDecoration(hintText: S.t('org_description_hint')),
              ),
              const SizedBox(height: 16),
              ExpansionTile(
                title: Text(S.t('org_more_info'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                childrenPadding: EdgeInsets.zero,
                children: [
                  _DisabledField(S.t('org_website')),
                  _DisabledField(S.t('org_address')),
                  _DisabledField(S.t('org_city')),
                  _DisabledField(S.t('org_postal')),
                  _DisabledField(S.t('org_country')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: currency,
                    dropdownColor: AppColors.card,
                    items: const ['XAF', 'XOF', 'EUR', 'USD', 'GBP']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => onCurrencyChanged(v ?? 'XAF'),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: onContinue, child: Text(S.t('org_continue')))),
      ],
    );
  }
}

class _DisabledField extends StatelessWidget {
  final String hint;
  const _DisabledField(this.hint);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
          enabled: false, decoration: InputDecoration(hintText: hint)),
    );
  }
}

class _StepParams extends StatelessWidget {
  final bool fondDeCaisse;
  final bool isEditing;
  final ValueChanged<bool> onFondDeCaisseChanged;
  final VoidCallback onBack;
  final VoidCallback onCreate;

  const _StepParams({
    required this.fondDeCaisse,
    required this.isEditing,
    required this.onFondDeCaisseChanged,
    required this.onBack,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Étape 2 sur 3 — Paramètres',
            style: TextStyle(
                color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        const Text('Logo (optionnel)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          height: 90,
          decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(14)),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.upload_rounded, color: AppColors.textSecondary),
                SizedBox(height: 6),
                Text('Importer une image',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ToggleTile(
          title: 'Fond de caisse',
          subtitle: 'Pour le tournoi par défaut (optionnel).',
          value: fondDeCaisse,
          onChanged: onFondDeCaisseChanged,
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.inputBorder),
                ),
                child: const Text('Retour'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                  onPressed: onCreate,
                  child: Text(isEditing ? 'Enregistrer' : S.t('org_create'))),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepDone extends StatelessWidget {
  final dynamic org;
  final VoidCallback onAccess;
  const _StepDone({required this.org, required this.onAccess});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Étape 3 sur 3',
              style: TextStyle(
                  color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Icon(Icons.check_circle,
              color: AppColors.primaryColor, size: 56),
          const SizedBox(height: 16),
          Text(S.t('org_created'),
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(org?.name ?? '',
              style: const TextStyle(
                  color: AppColors.primaryColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text(S.t('org_share_invite'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          OrganizationMatriculeCard(
            organizationName: org?.name ?? '',
            matricule: org?.joinCode ?? '',
          ),
          const SizedBox(height: 24),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: onAccess, child: Text(S.t('org_open_home')))),
        ],
      ),
    );
  }
}
