import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolekt/data/models.dart';
import 'package:kolekt/data/store.dart';
import 'package:kolekt/router.dart';
import 'package:kolekt/screens/cotisations/cotisation_detail_screen.dart';
import 'package:kolekt/screens/organizations/new_organization_screen.dart';
import 'package:kolekt/screens/organizations/join_organization_screen.dart';
import 'package:kolekt/screens/profile/mes_associations_screen.dart';
import 'package:kolekt/screens/sign_in_screen.dart';
import 'package:kolekt/services/ollama_service.dart';

void main() {
  test('organization permissions distinguish owner, admin, and member', () {
    final owner = Organization(
      id: 'owner_org',
      name: 'Owner group',
      ownerId: 'owner_user',
      currentUserRole: 'Propriétaire / Administrateur',
    );
    final admin = Organization(
      id: 'admin_org',
      name: 'Admin group',
      ownerId: 'other_user',
      currentUserRole: 'Administrateur',
    );
    final member = Organization(
      id: 'member_org',
      name: 'Member group',
      ownerId: 'other_user',
      currentUserRole: 'Membre',
    );

    expect(AppStore.instance.isOrganizationOwner(owner), isTrue);
    expect(AppStore.instance.canManageOrganization(owner), isTrue);
    expect(AppStore.instance.isOrganizationOwner(admin), isFalse);
    expect(AppStore.instance.canManageOrganization(admin), isTrue);
    expect(AppStore.instance.isOrganizationOwner(member), isFalse);
    expect(AppStore.instance.canManageOrganization(member), isFalse);
  });

  Future<void> pumpSignInScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
  }

  testWidgets('updates sign-in labels when the language changes',
      (WidgetTester tester) async {
    AppStore.instance.setLanguage(AppLanguage.fr);
    await pumpSignInScreen(tester);
    expect(find.text('Se connecter'), findsWidgets);

    AppStore.instance.setLanguage(AppLanguage.en);
    await tester.pump();
    expect(find.text('Sign in'), findsWidgets);

    AppStore.instance.setLanguage(AppLanguage.fr);
    await tester.pump();
    expect(find.text('Se connecter'), findsWidgets);
  });

  testWidgets('opens and returns from the account creation form',
      (WidgetTester tester) async {
    await pumpSignInScreen(tester);

    await tester.tap(find.text('Créer un compte'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Créer un compte'), findsWidgets);
    expect(find.byType(TextField), findsNWidgets(5));

    final returnLink = find.textContaining('Vous avez déjà un compte ?');
    await tester.ensureVisible(returnLink);
    await tester.tap(returnLink);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Se connecter'), findsWidgets);
  });

  testWidgets('the application create-account route renders the full form',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
    appRouter.go('/create-account');
    await tester.pumpAndSettle();

    expect(find.text('Créer un compte'), findsWidgets);
    expect(find.text('Nom complet *'), findsOneWidget);
    expect(find.text('Numéro de téléphone *'), findsWidgets);
    expect(find.text('Adresse e-mail *'), findsOneWidget);
  });

  testWidgets('join association screen asks for an association matricule',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: JoinOrganizationScreen()));

    expect(find.text('Rejoindre une association'), findsOneWidget);
    expect(find.text('Matricule de l’association'), findsOneWidget);
    expect(find.text('Rejoindre'), findsOneWidget);
  });

  testWidgets('sign-in form validates a missing email',
      (WidgetTester tester) async {
    await pumpSignInScreen(tester);
    final emailMode = find.byIcon(Icons.email_outlined).first;
    await tester.ensureVisible(emailMode);
    await tester.tap(emailMode);
    await tester.pump();
    expect(find.text('vous@exemple.com'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Se connecter'));
    await tester.pump();

    expect(find.text('Entrez votre adresse e-mail.'), findsOneWidget);
  });

  testWidgets('account creation form validates a missing phone number',
      (WidgetTester tester) async {
    await pumpSignInScreen(tester);
    await tester.tap(find.text('Créer un compte'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final submitButton = find.widgetWithText(ElevatedButton, 'Créer un compte');
    await tester.ensureVisible(submitButton);
    await tester.pump();
    await tester.tap(submitButton);
    await tester.pump();

    expect(find.textContaining('numéro valide'), findsOneWidget);
  });

  testWidgets('organization row is neutral and modify opens the edit form',
      (WidgetTester tester) async {
    AppStore.instance.organizations
      ..clear()
      ..add(Organization(
        id: 'org_1',
        name: 'Association test',
        ownerId: 'u_1',
        currentUserRole: 'Propriétaire',
      ));

    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
    appRouter.go('/profile/organizations');
    await tester.pumpAndSettle();

    final listTile = tester.widget<ListTile>(find.byType(ListTile).first);
    expect(listTile.onTap, isNull);

    await tester.tap(find.byTooltip('Actions sur l’association'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();

    expect(find.byType(NewOrganizationScreen), findsOneWidget);
    expect(find.text('Association test'), findsOneWidget);
  });

  test('pending campay payment creates a notification immediately', () async {
    final org = Organization(
      id: 'org_pending',
      name: 'Association pending',
      currency: 'XAF',
    );

    await AppStore.instance.recordPayment(
      org,
      'Alice',
      2000,
      'Cotisation test',
      status: 'pending',
    );

    expect(org.activityLog.isNotEmpty, isTrue);
    expect(org.activityLog.first.text, contains('en attente'));
    expect(org.activityLog.first.type, 'payment');
  });

  testWidgets('pending payment shows an En attente badge',
      (WidgetTester tester) async {
    final org = Organization(
      id: 'org_badge',
      name: 'Association badge',
      currency: 'XAF',
    );
    final member = Member(
      id: 'member_1',
      name: 'Alice',
      phone: '690000000',
      role: 'Membre',
    );
    final cotisation = Cotisation(
      id: 'cot_1',
      titre: 'Cotisation test',
      dateFin: DateTime.now().add(const Duration(days: 30)),
    );
    cotisation.participants.add(CotisationParticipant(member: member));
    org.membres.add(member);
    org.activityLog.add(
      ActivityEntry(
        text:
            'Alice a un paiement en attente de 2000 XAF sur "Cotisation test"',
        date: DateTime.now(),
        type: 'payment',
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: CotisationDetailScreen(org: org, cotisation: cotisation),
    ));
    await tester.pumpAndSettle();

    expect(find.text('En attente'), findsOneWidget);
  });

  test('ollama context summary includes member and tontine counts', () {
    final groups = [
      Organization(
        id: 'org_1',
        name: 'Association Alpha',
      )..membres.addAll([
          Member(id: 'm1', name: 'Alice', phone: '690000001', role: 'Membre'),
          Member(id: 'm2', name: 'Bob', phone: '690000002', role: 'Membre'),
        ]),
    ];
    groups.first.tontines.add(Tontine(
      id: 't1',
      libelle: 'Tontine test',
      membres: [
        Member(id: 'm1', name: 'Alice', phone: '690000001', role: 'Membre'),
        Member(id: 'm2', name: 'Bob', phone: '690000002', role: 'Membre'),
      ],
      beneficiaires: [
        Member(id: 'm1', name: 'Alice', phone: '690000001', role: 'Membre'),
      ],
    ));

    final summary = OllamaService.buildContextSummary(groups);

    expect(summary, contains('Association Alpha'));
    expect(summary, contains('"memberCount": 2'));
    expect(summary, contains('"tontineCount": 1'));
  });

  test(
      'ollama app context includes current user, payments, and recent activity',
      () {
    final org = Organization(
      id: 'org_app',
      name: 'Association app',
      currency: 'XAF',
    );
    org.membres.add(Member(
      id: 'm_1',
      name: 'Alice',
      phone: '690000001',
      role: 'Membre',
    ));
    org.cotisations.add(Cotisation(
      id: 'cot_1',
      titre: 'Cotisation mensuelle',
      dateFin: DateTime.now().add(const Duration(days: 30)),
    )..participants.add(CotisationParticipant(
        member: org.membres.first,
        montantPaye: 5000,
        montantAttendu: 5000,
      )));
    org.activityLog.add(ActivityEntry(
      text: 'Alice a payé 5000 XAF sur Cotisation mensuelle',
      date: DateTime.now(),
      type: 'payment',
    ));

    AppStore.instance.currentAccount = Account(
      id: 'user_1',
      name: 'Admin',
      phone: '690000000',
      email: 'admin@example.com',
      password: 'secret',
      matricule: 'MAT-001',
    );
    AppStore.instance.organizations
      ..clear()
      ..add(org);

    final summary = OllamaService.buildAppContextSummary(AppStore.instance);

    expect(summary, contains('"currentUser"'));
    expect(summary, contains('"organizations"'));
    expect(summary, contains('"payments"'));
    expect(summary, contains('Cotisation mensuelle'));
  });

  test('ollama answers member count questions directly from app data',
      () async {
    final organization = Organization(
      id: 'org_count',
      name: 'Association Alpha',
    )..membres.addAll([
        Member(id: 'count_1', name: 'Alice', phone: '690000001'),
        Member(id: 'count_2', name: 'Bob', phone: '690000002'),
      ]);

    final answer = await const OllamaService().ask(
        'Combien de membres dans Association Alpha ?',
        organizations: [organization]);

    expect(answer, 'Il y a 2 membre(s) dans Association Alpha.');
  });

  test('organization matricule survives snapshot serialization', () {
    final original = Organization(
      id: 'org_code',
      name: 'Association code',
      joinCode: 'KOL-12AB34CD',
      description: 'Données préexistantes',
    )..membres.add(Member(id: 'm1', name: 'Alice', phone: '690000001'));

    final restored = Organization.fromJson(original.toJson());

    expect(restored.joinCode, 'KOL-12AB34CD');
    expect(restored.inviteUrl, 'https://nova.app/join/org_code');
    expect(restored.description, 'Données préexistantes');
    expect(restored.membres.single.name, 'Alice');
  });
}
