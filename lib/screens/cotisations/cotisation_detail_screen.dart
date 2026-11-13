import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../services/campay_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class CotisationDetailScreen extends StatefulWidget {
  final Organization org;
  final Cotisation cotisation;
  const CotisationDetailScreen(
      {super.key, required this.org, required this.cotisation});

  @override
  State<CotisationDetailScreen> createState() => _CotisationDetailScreenState();
}

class _CotisationDetailScreenState extends State<CotisationDetailScreen> {
  int _filter = 0; // Tous / Payé / Non payé / Partiel
  bool _campayLoading = false;
  final _campayService = CampayService();

  @override
  void initState() {
    super.initState();
    _applyLatePenalties();
    AppStore.instance
        .syncCotisationPeriods(widget.org, widget.cotisation)
        .then((_) {
      if (mounted) setState(() {});
    }).catchError((Object error) {
      debugPrint('Synchronisation de période impossible: $error');
    });
  }

  Future<void> _applyLatePenalties() async {
    try {
      await AppStore.instance.applyCotisationPenalties(
        widget.org,
        widget.cotisation,
        DateTime.now(),
      );
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('Application des sanctions impossible: $error');
    }
  }

  double _remainingFor(CotisationParticipant participant) {
    participant.appliquerPeriode(widget.cotisation.currentPeriodKey());
    return (participant.montantTotalAttendu - participant.montantPaye)
        .clamp(0, double.infinity);
  }

  CotisationParticipant? get _myParticipant {
    final myMember = AppStore.instance.myMemberIn(widget.org);
    if (myMember == null) return null;
    for (final participant in widget.cotisation.participants) {
      if (participant.member.id == myMember.id) return participant;
    }
    return null;
  }

  bool _isCurrentUserParticipant(CotisationParticipant participant) {
    final accountId = AppStore.instance.currentAccount?.id;
    if (accountId == null) return false;
    if (participant.member.ownerAccountId == accountId) return true;
    return widget.org.ownerId == accountId &&
        participant.member.role.toLowerCase() == 'propriétaire';
  }

  bool get _canReconcileCampay =>
      AppStore.instance.canManageOrganization(widget.org);

  Future<void> _addParticipant() async {
    final eligibleMembers = widget.org.membres
        .where((member) => !widget.cotisation.participants
            .any((participant) => participant.member.id == member.id))
        .toList(growable: false);
    if (eligibleMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tous les membres sont déjà ajoutés.')),
      );
      return;
    }
    final member = await showModalBottomSheet<Member>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text('Ajouter un membre',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...eligibleMembers.map((member) => ListTile(
                  leading: MemberAvatar(name: member.name),
                  title: Text(member.name),
                  subtitle: Text(member.phone),
                  onTap: () => Navigator.pop(sheetContext, member),
                )),
          ],
        ),
      ),
    );
    if (!mounted || member == null) return;
    try {
      await AppStore.instance
          .addCotisationParticipant(widget.org, widget.cotisation, member);
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) _showMessage('Ajout impossible : $error');
    }
  }

  Future<void> _configurePenalty() async {
    final controller = TextEditingController(
      text: widget.cotisation.penaliteJournaliere > 0
          ? widget.cotisation.penaliteJournaliere.toStringAsFixed(0)
          : '',
    );
    final amount = await showDialog<double?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Sanction de retard'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Montant par jour (${widget.org.currency})',
            helperText: 'Saisissez 0 pour désactiver la sanction.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              double.tryParse(controller.text.trim()),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || amount == null) return;
    if (amount < 0) {
      _showMessage('Le montant ne peut pas être négatif.');
      return;
    }
    try {
      await AppStore.instance.configureCotisationPenalty(
        widget.org,
        widget.cotisation,
        amount,
      );
      await _applyLatePenalties();
      if (mounted) {
        _showMessage(amount == 0
            ? 'Sanction désactivée.'
            : 'Sanction de ${amount.toStringAsFixed(0)} ${widget.org.currency} par jour enregistrée.');
      }
    } catch (error) {
      if (mounted) _showMessage('Configuration impossible : $error');
    }
  }

  Future<void> _reorderParticipants() async {
    if (widget.cotisation.participants.length < 2) return;
    final orderedParticipants = List<CotisationParticipant>.of(
      widget.cotisation.participants,
    );
    final orderedResult =
        await showModalBottomSheet<List<CotisationParticipant>>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.65,
          child: ReorderableListView(
            padding: const EdgeInsets.all(16),
            footer: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FilledButton(
                onPressed: () => Navigator.pop(
                  sheetContext,
                  List<CotisationParticipant>.of(orderedParticipants),
                ),
                child: const Text('Enregistrer l’ordre'),
              ),
            ),
            children: [
              for (var index = 0; index < orderedParticipants.length; index++)
                ListTile(
                  key: ValueKey(orderedParticipants[index].member.id),
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(orderedParticipants[index].member.name),
                  trailing: const Icon(Icons.drag_handle),
                ),
            ],
            onReorder: (oldIndex, newIndex) {
              setSheetState(() {
                if (newIndex > oldIndex) newIndex--;
                final participant = orderedParticipants.removeAt(oldIndex);
                orderedParticipants.insert(newIndex, participant);
              });
            },
          ),
        ),
      ),
    );
    if (!mounted || orderedResult == null) return;
    widget.cotisation.participants
      ..clear()
      ..addAll(orderedResult);
    for (var index = 0;
        index < widget.cotisation.participants.length;
        index++) {
      widget.cotisation.participants[index].ordrePassage = index + 1;
    }
    await AppStore.instance.persistOrganization(widget.org);
    if (mounted) setState(() {});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _reconcileHistoricalPayment(
      CotisationParticipant participant) async {
    final referenceController = TextEditingController();
    final amountController = TextEditingController(
      text: (participant.montantAttendu - participant.montantPaye)
          .clamp(0, double.infinity)
          .toStringAsFixed(0),
    );
    var confirmed = false;
    final details = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Récupérer un paiement Campay'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Vérifiez le paiement dans votre historique marchand Campay avant de le rapprocher pour ${participant.member.name}.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Référence Campay',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Montant (${widget.org.currency})',
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: confirmed,
                  onChanged: (value) =>
                      setDialogState(() => confirmed = value ?? false),
                  title: const Text(
                    'J’ai vérifié dans Campay que ce paiement a réussi.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: confirmed &&
                      referenceController.text.trim().isNotEmpty &&
                      double.tryParse(amountController.text.trim()) != null
                  ? () => Navigator.pop(dialogContext, {
                        'reference': referenceController.text.trim(),
                        'amount': double.parse(amountController.text.trim()),
                      })
                  : null,
              child: const Text('Rapprocher'),
            ),
          ],
        ),
      ),
    );
    referenceController.dispose();
    amountController.dispose();
    if (details == null || !mounted) return;

    try {
      await _campayService.reconcileHistoricalPayment(
        organizationId: widget.org.id,
        cotisationId: widget.cotisation.id,
        memberId: participant.member.id,
        providerReference: details['reference'] as String,
        amount: details['amount'] as double,
      );
      participant.montantPaye += details['amount'] as double;
      await AppStore.instance.loadOrganizations();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paiement rapproché et enregistré.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _statusFor(CotisationParticipant participant) {
    final hasPendingPayment = widget.org.activityLog.any(
      (entry) =>
          entry.type == 'payment' &&
          entry.text.contains(participant.member.name) &&
          entry.text.contains(widget.cotisation.titre) &&
          entry.text.contains('en attente'),
    );
    if (hasPendingPayment) return 'En attente';
    return participant.statut;
  }

  List<CotisationParticipant> get _filtered {
    final all = widget.cotisation.participants;
    switch (_filter) {
      case 1:
        return all.where((p) => _statusFor(p) == 'Payé').toList();
      case 2:
        return all.where((p) => _statusFor(p) == 'Non payé').toList();
      case 3:
        return all.where((p) => _statusFor(p) == 'Partiel').toList();
      default:
        return all;
    }
  }

  Future<void> _encaisser(CotisationParticipant p) async {
    final remaining = _remainingFor(p);
    final controller = TextEditingController(
      text: remaining > 0 ? remaining.toStringAsFixed(0) : '',
    );
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Encaisser — ${p.member.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Montant en ${widget.org.currency}',
            helperText:
                'Reste à payer cette période : ${remaining.toStringAsFixed(0)} ${widget.org.currency}',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(controller.text.trim())),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted) return;
    if (amount != null && amount > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Le montant dépasse le restant dû (${remaining.toStringAsFixed(0)} ${widget.org.currency}).'),
        ),
      );
      return;
    }
    if (amount != null && amount > 0) {
      p.appliquerPeriode(widget.cotisation.currentPeriodKey());
      setState(() => p.montantPaye += amount);
      await AppStore.instance.recordPayment(
        widget.org,
        p.member.name,
        amount,
        widget.cotisation.titre,
      );
      await AppStore.instance.persistOrganization(widget.org);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Paiement de ${amount.toStringAsFixed(0)} ${widget.org.currency} enregistré pour ${p.member.name}')),
        );
      }
    }
  }

  Future<void> _cotiser() async {
    final participant = _myParticipant;
    if (participant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vous ne faites pas partie de cette cotisation.')),
      );
      return;
    }
    final remaining = _remainingFor(participant);
    if (remaining <= 0 && participant.montantAttendu > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Votre cotisation est déjà réglée.')),
      );
      return;
    }

    final phoneController = TextEditingController(
      text: AppStore.instance.userPhone ?? participant.member.phone,
    );
    final amountController = TextEditingController(
      text: remaining > 0 ? remaining.toStringAsFixed(0) : '',
    );
    final paymentDetails = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Cotiser avec Campay'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration:
                  const InputDecoration(labelText: 'Numéro mobile money'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: 'Montant (${widget.org.currency})'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final phone = phoneController.text.trim();
              final amount = double.tryParse(amountController.text.trim());
              if (phone.isEmpty || amount == null || amount <= 0) return;
              if (remaining > 0 && amount > remaining) return;
              Navigator.pop(dialogContext, {'phone': phone, 'amount': amount});
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    phoneController.dispose();
    amountController.dispose();
    if (paymentDetails == null || !mounted) return;

    setState(() => _campayLoading = true);
    try {
      final result = await _campayService.startCollection(
        organizationId: widget.org.id,
        cotisationId: widget.cotisation.id,
        memberId: participant.member.id,
        phone: paymentDetails['phone'] as String,
        amount: paymentDetails['amount'] as double,
      );
      final transactionId = result['transactionId'] as String?;
      if (!mounted) return;
      final ussdCode = result['ussdCode'] as String?;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Demande envoyée'),
          content: Text(
            ussdCode == null || ussdCode.isEmpty
                ? (result['message'] as String? ??
                    'Confirmez le paiement sur votre téléphone.')
                : 'Confirmez le paiement sur votre téléphone avec le code ${ussdCode}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (transactionId == null) {
        throw Exception(
            'La demande est envoyée, mais son suivi est indisponible.');
      }

      await AppStore.instance.recordPayment(
        widget.org,
        participant.member.name,
        paymentDetails['amount'] as double,
        widget.cotisation.titre,
        status: 'pending',
      );

      var transactionStatus =
          (result['status'] as String? ?? 'PENDING').toUpperCase();
      for (var attempt = 0;
          attempt < 30 && transactionStatus == 'PENDING';
          attempt++) {
        await Future<void>.delayed(const Duration(seconds: 3));
        transactionStatus =
            (await _campayService.getTransactionStatus(transactionId))
                .toUpperCase();
      }

      if (!mounted) return;
      if (transactionStatus == 'SUCCESSFUL') {
        try {
          await AppStore.instance.loadOrganizations();
        } catch (error) {
          debugPrint('Actualisation des organisations impossible: $error');
        }
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Paiement Campay confirmé et enregistré.')),
          );
        }
      } else if (transactionStatus == 'FAILED' ||
          transactionStatus == 'CANCELLED') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Le paiement Campay a échoué ou a été annulé.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Paiement en attente de confirmation Campay. Revenez consulter la cotisation dans un instant.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _campayLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cotisation;
    final nextDueDate = c.nextDueDate();
    final totalAttendu =
        c.participants.fold(0.0, (s, p) => s + p.montantTotalAttendu);
    final progress =
        totalAttendu > 0 ? (c.collecte / totalAttendu).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(c.titre),
        actions: [
          if (_canReconcileCampay)
            PopupMenuButton<String>(
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Modifier')),
                PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Dupliquer cette cotisation')),
                PopupMenuItem(
                    value: 'delete', child: Text('Supprimer cette cotisation')),
                PopupMenuItem(
                    value: 'transactions', child: Text('Transactions')),
                PopupMenuItem(value: 'report', child: Text('Report')),
              ],
              onSelected: (v) {
                if (v == 'delete') {
                  widget.org.cotisations.remove(c);
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Paiement ${c.frequence.toLowerCase()}',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(
              'Prochaine échéance : ${nextDueDate.day.toString().padLeft(2, '0')}/${nextDueDate.month.toString().padLeft(2, '0')}/${nextDueDate.year}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Text('COLLECTÉ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text('${c.collecte.toStringAsFixed(0)} ${widget.org.currency}',
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            if (totalAttendu > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.inputBg,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                  'sur ${totalAttendu.toStringAsFixed(0)} ${widget.org.currency} attendus',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
            const SizedBox(height: 6),
            Builder(builder: (context) {
              final myMember = AppStore.instance.myMemberIn(widget.org);
              final me =
                  c.participants.where((p) => p.member.id == myMember?.id);
              final mine = me.isEmpty ? 0.0 : me.first.montantPaye;
              return Text(
                  'Vous avez cotisé ${mine.toStringAsFixed(0)} ${widget.org.currency}',
                  style: TextStyle(color: AppColors.textSecondary));
            }),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (_canReconcileCampay) ...[
                  OutlinedButton.icon(
                    onPressed: _addParticipant,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Ajouter un membre'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _reorderParticipants,
                    icon: const Icon(Icons.sort),
                    label: const Text('Ordre de passage'),
                  ),
                ],
                if (_canReconcileCampay)
                  OutlinedButton.icon(
                    onPressed: _configurePenalty,
                    icon: const Icon(Icons.gavel_outlined),
                    label: Text(c.penaliteJournaliere > 0
                        ? 'Sanction ${c.penaliteJournaliere.toStringAsFixed(0)}/${widget.org.currency}/jour'
                        : 'Définir sanction'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text('Liste des participants',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ChipTabs(
              labels: const ['Tous', 'Payé', 'Non payé', 'Partiel'],
              selected: _filter,
              onChanged: (i) => setState(() => _filter = i),
            ),
            const SizedBox(height: 12),
            if (_filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('Aucun participant dans ce filtre.',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              ..._filtered.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: MemberAvatar(name: p.member.name),
                      title: Text(p.member.name),
                      subtitle: Text(
                        '${p.ordrePassage > 0 ? '#${p.ordrePassage} • ' : ''}${p.montantPaye.toStringAsFixed(0)} / ${p.montantAttendu.toStringAsFixed(0)} ${widget.org.currency}${p.penaliteCumulee > 0 ? ' • Amende ${p.penaliteCumulee.toStringAsFixed(0)}' : ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_canReconcileCampay && _statusFor(p) != 'Payé')
                            IconButton(
                              icon: const Icon(Icons.history_rounded, size: 20),
                              tooltip: 'Récupérer un ancien paiement Campay',
                              onPressed: () => _reconcileHistoricalPayment(p),
                            ),
                          _StatusBadge(label: _statusFor(p)),
                          if (_isCurrentUserParticipant(p) ||
                              _canReconcileCampay)
                            IconButton(
                              icon: const Icon(Icons.payments_outlined,
                                  size: 20, color: AppColors.primaryColor),
                              tooltip: _isCurrentUserParticipant(p)
                                  ? 'Cotiser avec Campay'
                                  : 'Enregistrer un paiement',
                              onPressed: _isCurrentUserParticipant(p)
                                  ? (_campayLoading ? null : _cotiser)
                                  : _canReconcileCampay
                                      ? () => _encaisser(p)
                                      : null,
                            ),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _campayLoading ? null : _cotiser,
              icon: _campayLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.payments_outlined),
              label: const Text('Cotiser'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  const _StatusBadge({required this.label});

  Color get _bg {
    switch (label) {
      case 'Payé':
        return const Color(0xFF1F3A24);
      case 'Partiel':
        return const Color(0xFF3A331F);
      case 'En attente':
        return const Color(0xFF3A331F);
      default:
        return AppColors.errorBg;
    }
  }

  Color get _fg {
    switch (label) {
      case 'Payé':
        return const Color(0xFF5FCB6E);
      case 'Partiel':
        return const Color(0xFFCBA95F);
      case 'En attente':
        return const Color(0xFFFFD166);
      default:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style:
              TextStyle(color: _fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
