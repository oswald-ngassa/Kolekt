import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  String _pieceType = 'CNI';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KYC')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Selfie (photo de vous)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Center(
              child: CircleAvatar(radius: 40, backgroundColor: AppColors.inputBg, child: Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 20),
            const SectionLabel('Identité'),
            Row(children: const [
              Expanded(child: TextField(decoration: InputDecoration(hintText: 'Prénom'))),
              SizedBox(width: 10),
              Expanded(child: TextField(decoration: InputDecoration(hintText: 'Nom'))),
            ]),
            const SizedBox(height: 12),
            Row(children: const [
              Expanded(child: TextField(decoration: InputDecoration(hintText: 'Date de naissance'))),
              SizedBox(width: 10),
              Expanded(child: TextField(enabled: false, decoration: InputDecoration(hintText: 'Nationalité', suffixText: 'Cameroon'))),
            ]),
            const SizedBox(height: 12),
            Row(
              children: [
                const CountryCodePicker(initialSelection: 'CM'),
                const Expanded(child: TextField(decoration: InputDecoration(hintText: 'Téléphone'))),
              ],
            ),
            const SizedBox(height: 20),
            const SectionLabel('Adresse'),
            const TextField(decoration: InputDecoration(hintText: 'Adresse')),
            const SizedBox(height: 12),
            Row(children: const [
              Expanded(child: TextField(decoration: InputDecoration(hintText: 'Ville'))),
              SizedBox(width: 10),
              Expanded(child: TextField(enabled: false, decoration: InputDecoration(hintText: 'Pays de résidence', suffixText: 'Cameroon'))),
            ]),
            const SizedBox(height: 20),
            const SectionLabel("Pièce d'identité"),
            DropdownButtonFormField<String>(
              initialValue: _pieceType,
              dropdownColor: AppColors.card,
              items: const ['CNI', 'Passeport', "Carte d'électeur"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _pieceType = v ?? 'CNI'),
            ),
            const SizedBox(height: 12),
            Row(children: const [
              Expanded(child: TextField(decoration: InputDecoration(hintText: 'Numéro de la pièce'))),
              SizedBox(width: 10),
              Expanded(child: TextField(decoration: InputDecoration(hintText: "Date d'expiration"))),
            ]),
            const SizedBox(height: 20),
            const SectionLabel('Photos'),
            Text('Document recto', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            _UploadBox(),
            const SizedBox(height: 14),
            Text('Document verso', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            _UploadBox(),
            const SizedBox(height: 8),
            Text('Renseignez toutes les images avant soumission.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), foregroundColor: AppColors.textPrimary, side: BorderSide(color: AppColors.inputBorder)),
              child: const Text('Enregistrer le brouillon'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () => context.pop(), child: const Text('Soumettre le KYC')),
          ],
        ),
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_rounded, color: AppColors.textSecondary, size: 20),
            Text('Importer une image', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
