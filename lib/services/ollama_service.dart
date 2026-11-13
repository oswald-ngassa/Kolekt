import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/store.dart';
import '../data/models.dart';

class OllamaService {
  final String baseUrl;
  final String model;

  const OllamaService({
    this.baseUrl = 'http://localhost:11434',
    this.model = 'llama2:latest',
  });

  Future<String> ask(String question, {List<Organization>? organizations}) async {
    final response = StringBuffer();
    await for (final chunk in askStream(question, organizations: organizations)) {
      response.write(chunk);
    }
    return response.toString().trim();
  }

  Stream<String> askStream(
    String question, {
    List<Organization>? organizations,
  }) async* {
    final dataAnswer = _answerCountQuestion(
      question,
      organizations ?? AppStore.instance.organizations,
    );
    if (dataAnswer != null) {
      yield dataAnswer;
      return;
    }

    final appContext = buildAppContextSummary(AppStore.instance);
    final request = http.Request('POST', Uri.parse('$baseUrl/api/generate'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
      'model': model,
      'stream': true,
      'keep_alive': '5m',
      'options': {
        'num_ctx': 4096,
        'num_predict': 96,
        'temperature': 0,
      },
      'prompt': _buildPrompt(question, organizations ?? AppStore.instance.organizations, appContext),
    });

    final client = http.Client();
    try {
      final response = await client.send(request).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Délai de connexion à Ollama dépassé.'),
          );

      if (response.statusCode != 200) {
        throw Exception('Ollama indisponible : ${response.statusCode}');
      }

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .timeout(const Duration(seconds: 45))) {
        if (line.isEmpty) continue;
        final data = jsonDecode(line) as Map<String, dynamic>;
        final chunk = data['response'] as String?;
        if (chunk != null && chunk.isNotEmpty) yield chunk;
      }
    } finally {
      client.close();
    }
  }

  static String buildContextSummary(List<Organization> organizations) {
    final data = {
      'organizationCount': organizations.length,
      'organizations': organizations.map((org) {
        final tontines = org.tontines.length;
        final members = org.membres.length;
        final cotisations = org.cotisations.length;
        final recentPayments = org.activityLog
            .where((entry) => entry.type == 'payment')
            .map((entry) => {
                  'text': entry.text,
                  'date': entry.date.toIso8601String(),
                })
            .toList();
        return {
          'id': org.id,
          'name': org.name,
          'currency': org.currency,
          'memberCount': members,
          'tontineCount': tontines,
          'cotisationCount': cotisations,
          'paymentCount': org.activityLog.where((entry) => entry.type == 'payment').length,
          'ownerId': org.ownerId,
          'currentUserRole': org.currentUserRole,
          'recentPayments': recentPayments,
          'members': org.membres.map((member) => {
            'id': member.id,
            'name': member.name,
            'phone': member.phone,
            'role': member.role,
          }).toList(),
        };
      }).toList(),
    };
    return jsonEncode(data);
  }

  static String buildAppContextSummary(AppStore appStore) {
    final summary = {
      'currentUser': appStore.currentAccount == null
          ? null
          : {
              'id': appStore.currentAccount!.id,
              'name': appStore.currentAccount!.name,
              'phone': appStore.currentAccount!.phone,
              'email': appStore.currentAccount!.email,
              'role': appStore.activeOrg != null
                  ? appStore.activeOrg!.currentUserRole
                  : null,
            },
      'organizationCount': appStore.organizations.length,
      'organizations': appStore.organizations.map((org) {
        final payments = org.activityLog
            .where((entry) => entry.type == 'payment')
            .map((entry) => {
                  'text': entry.text,
                  'date': entry.date.toIso8601String(),
                })
            .toList();

        return {
          'id': org.id,
          'name': org.name,
          'currency': org.currency,
          'ownerId': org.ownerId,
          'currentUserRole': org.currentUserRole,
          'memberCount': org.membres.length,
          'tontineCount': org.tontines.length,
          'cotisationCount': org.cotisations.length,
          'members': org.membres.map((member) => {
            'id': member.id,
            'name': member.name,
            'phone': member.phone,
            'role': member.role,
            'ownerAccountId': member.ownerAccountId,
          }).toList(),
          'cotisations': org.cotisations.map((cotisation) => {
            'id': cotisation.id,
            'title': cotisation.titre,
            'frequency': cotisation.frequence,
            'participants': cotisation.participants.map((participant) => {
              'memberName': participant.member.name,
              'amountPaid': participant.montantPaye,
              'amountExpected': participant.montantTotalAttendu,
              'status': participant.statut,
            }).toList(),
          }).toList(),
          'payments': payments,
        };
      }).toList(),
    };
    return jsonEncode(summary);
  }

  static String? _answerCountQuestion(
    String question,
    List<Organization> organizations,
  ) {
    final normalizedQuestion = question.toLowerCase();
    if (!RegExp(r'combien|nombre|total|effectif').hasMatch(normalizedQuestion)) {
      return null;
    }

    final organization = organizations.cast<Organization?>().firstWhere(
          (org) => org != null &&
              normalizedQuestion.contains(org.name.toLowerCase()),
          orElse: () => null,
        );
    final requested = organization == null
        ? organizations
        : <Organization>[organization];

    if (RegExp(r'association|organisation').hasMatch(normalizedQuestion) &&
        !RegExp(r'membre|tontine|cotisation').hasMatch(normalizedQuestion)) {
      return 'Vous avez ${organizations.length} association(s).';
    }
    if (RegExp(r'membre|adhérent').hasMatch(normalizedQuestion)) {
      final count = requested.fold<int>(
        0,
        (total, org) => total + org.membres.length,
      );
      final scope = organization == null ? 'dans vos associations' : 'dans ${organization.name}';
      return 'Il y a $count membre(s) $scope.';
    }
    if (RegExp(r'tontine').hasMatch(normalizedQuestion)) {
      final count = requested.fold<int>(
        0,
        (total, org) => total + org.tontines.length,
      );
      final scope = organization == null ? 'dans vos associations' : 'dans ${organization.name}';
      return 'Il y a $count tontine(s) $scope.';
    }
    if (RegExp(r'cotisation').hasMatch(normalizedQuestion)) {
      final count = requested.fold<int>(
        0,
        (total, org) => total + org.cotisations.length,
      );
      final scope = organization == null ? 'dans vos associations' : 'dans ${organization.name}';
      return 'Il y a $count cotisation(s) $scope.';
    }
    return null;
  }

  String _buildPrompt(String question, List<Organization> organizations, [String? appContextJson]) {
    final contextJson = appContextJson ?? buildContextSummary(organizations);
    return '''
Tu es un assistant local de données Kolekt.
Tu ne dois répondre qu'à partir des données fournies dans le JSON ci-dessous.
Le contexte inclut l’utilisateur actuel, les organisations, les membres, les tontines, les cotisations et les paiements de l’application.
Ne fais pas d'hypothèses hors du contexte.
Si l'info n'est pas disponible, dis-le clairement.

Contexte JSON :
$contextJson

Question utilisateur :
$question

Réponds en français, très brièvement (une phrase), avec le résultat exact des données.
''';
  }
}
