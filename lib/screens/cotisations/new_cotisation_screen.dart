import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../widgets/shared.dart';

class NewCotisationScreen extends StatefulWidget {
  final Organization org;
  const NewCotisationScreen({super.key, required this.org});

  @override
  State<NewCotisationScreen> createState() => _NewCotisationScreenState();
}

class _NewCotisationScreenState extends State<NewCotisationScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _montantController = TextEditingController();
  final _penaliteController = TextEditingController();
  String _frequence = 'Mensuelle';
  late DateTime _dateFin = _nextDueDate(_frequence);
  String _visibilite = 'Privée';
  bool _allMembers = true;
  final Set<String> _selectedMemberIds = {};
  bool _sanctions = false;
  bool _payerAvecFrais = false;

  DateTime _nextDueDate(String frequence) {
    final now = DateTime.now();
    if (frequence == 'Journalière') {
      return now.add(const Duration(days: 1));
    }
    if (frequence == 'Hebdomadaire') {
      return now.add(const Duration(days: 7));
    }
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    return DateTime(nextMonth.year, nextMonth.month, now.day.clamp(1, lastDay));
  }

  String get _amountHint => switch (_frequence) {
        'Journalière' => 'Montant à cotiser par membre et par jour *',
        'Hebdomadaire' => 'Montant à cotiser par membre et par semaine *',
        _ => 'Montant à cotiser par membre et par mois *',
      };

  void _setFrequence(String frequence) {
    setState(() {
      _frequence = frequence;
      _dateFin = _nextDueDate(frequence);
    });
  }

  Future<void> _create() async {
    final montantAttendu = double.tryParse(_montantController.text.trim());
    final participants = _allMembers
        ? widget.org.membres
        : widget.org.membres
            .where((member) => _selectedMemberIds.contains(member.id))
            .toList();
    if (_titleController.text.trim().isEmpty ||
        montantAttendu == null ||
        montantAttendu <= 0 ||
        participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Renseignez le titre, un montant valide et au moins un membre.'),
        ),
      );
      return;
    }
    final c = Cotisation(
      id: AppStore.instance.nextId(),
      titre: _titleController.text.trim(),
      type: _frequence,
      frequence: _frequence,
      visibilite: _visibilite,
      dateFin: _dateFin,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      sanctionsAutomatiques: _sanctions,
      penaliteJournaliere:
          _sanctions ? double.tryParse(_penaliteController.text.trim()) ?? 0 : 0,
      payerAvecFrais: _payerAvecFrais,
      participants: participants.asMap().entries.map((entry) {
        return CotisationParticipant(
          member: entry.value,
          montantAttendu: montantAttendu,
          ordrePassage: entry.key + 1,
        );
      }).toList(),
    );
    try {
      await AppStore.instance.addCotisation(widget.org, c);
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
          SnackBar(content: Text('Cotisation "${c.titre}" créée')));
      context.pop();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFin,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _dateFin = picked);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _montantController.dispose();
    _penaliteController.dispose();
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
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Titre *')),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Fréquence',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            ChipTabs(
              labels: const ['Journalière', 'Hebdomadaire', 'Mensuelle'],
              selected: const [
                'Journalière',
                'Hebdomadaire',
                'Mensuelle',
              ].indexOf(_frequence),
              onChanged: (index) => _setFrequence(const [
                    'Journalière',
                    'Hebdomadaire',
                    'Mensuelle',
                  ][index]),
            ),
            const SizedBox(height: 12),
            ChipTabs(
                labels: const ['Privée', 'Publique'],
                selected: _visibilite == 'Privée' ? 0 : 1,
                onChanged: (i) => setState(
                    () => _visibilite = i == 0 ? 'Privée' : 'Publique')),
            const SizedBox(height: 16),
            TextField(
              controller: _montantController,
                keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(hintText: _amountHint),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Membres ciblés',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 4),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Tous les membres'),
                  icon: Icon(Icons.groups_outlined),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Choisir'),
                  icon: Icon(Icons.person_search_outlined),
                ),
              ],
              selected: {_allMembers},
              onSelectionChanged: (selection) =>
                  setState(() => _allMembers = selection.first),
            ),
            if (!_allMembers)
              ...widget.org.membres.map(
                (member) => CheckboxListTile(
                  contentPadding: const EdgeInsets.only(left: 12),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(member.name),
                  value: _selectedMemberIds.contains(member.id),
                  onChanged: (selected) => setState(() {
                    if (selected == true) {
                      _selectedMemberIds.add(member.id);
                    } else {
                      _selectedMemberIds.remove(member.id);
                    }
                  }),
                ),
              ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Prochaine échéance *',
                    suffixIcon: Icon(Icons.calendar_today, size: 18)),
                child: Text(
                    '${_dateFin.day.toString().padLeft(2, '0')}/${_dateFin.month.toString().padLeft(2, '0')}/${_dateFin.year}'),
              ),
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text("Plus d'options",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              childrenPadding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 10),
                TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        hintText: 'Description (optionnelle)')),
                const SizedBox(height: 14),
                const SectionLabel('Tous les membres'),
                const SectionLabel('Bénéficiaires (optionnel)'),
                ToggleTile(
                    title: 'Sanctions automatiques',
                    value: _sanctions,
                    onChanged: (v) => setState(() => _sanctions = v)),
                if (_sanctions) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _penaliteController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText:
                          'Sanction par jour de retard (${widget.org.currency})',
                      hintText: 'Ex. 500',
                    ),
                  ),
                ],
                ToggleTile(
                    title: 'Payer avec les frais de retrait',
                    value: _payerAvecFrais,
                    onChanged: (v) => setState(() => _payerAvecFrais = v)),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: _create, child: const Text('Créer tontine')),
          ],
        ),
      ),
    );
  }
}
