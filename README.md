# nOVa — Application Flutter

Supabase gère l'authentification, les profils et les espaces d'organisation.
Chaque organisation est sauvegardée avec un snapshot de ses membres, cotisations,
tontines, invitations, gestionnaires et comptes. Les données de paiement et
l'activité détaillée ne sont pas encore modélisées comme des écritures séparées.

## Lancer le projet

Exécutez ou réexécutez [`supabase/schema.sql`](supabase/schema.sql) dans le SQL
Editor pour créer la table `organizations`, ses règles RLS et la fonction de
suppression de compte, puis activez le fournisseur e-mail dans Authentication.
Dans **Authentication → Sign In / Providers**, désactivez **Confirm email** pour
permettre l'ouverture immédiate d'une session. L'application utilise email et mot
de passe; le numéro de téléphone est enregistré comme information du profil, pas
comme méthode de connexion.

```bash
flutter pub get
flutter run -d chrome \
    --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
    --dart-define=SUPABASE_ANON_KEY=<publishable-or-anon-key>
```

La clé utilisée dans l'application doit être la clé publique `anon`/publishable,
jamais une clé `service_role`. Pour les autres plateformes, passez les mêmes
`--dart-define` à `flutter run` ou à la commande de build correspondante.

## Tester l'inscription et l'authentification

Les tests widget vérifient l'affichage de la connexion, l'ouverture et le retour
du formulaire d'inscription, ainsi que les validations de champs. Ils ne créent
pas de compte et ne nécessitent pas de connexion Supabase.

Sous Windows PowerShell, lancez toute la vérification avec le script fourni :

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\test-auth.ps1
```

Les commandes équivalentes, à exécuter depuis la racine du projet :

```powershell
flutter pub get
flutter test test/widget_test.dart test/auth_flow_test.dart --timeout 30s
flutter analyze lib/screens/sign_in_screen.dart test/widget_test.dart test/auth_flow_test.dart
```

Pour lancer un test précis :

```powershell
flutter test test/auth_flow_test.dart --plain-name="opens and returns from the account creation form" --timeout 30s
flutter test test/auth_flow_test.dart --plain-name="sign-in form validates a missing email" --timeout 30s
flutter test test/auth_flow_test.dart --plain-name="account creation form validates a missing phone number" --timeout 30s
```

Pour vérifier les appels réels d'inscription et de connexion, démarrez l'app
avec un projet Supabase de test et un utilisateur de test autorisé. N'utilisez
pas de clé `service_role` ni de mot de passe de production dans le code ou les
fichiers de test :

```powershell
flutter run -d chrome --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<publishable-or-anon-key>
```

Utilisez uniquement un compte jetable du projet de test pour valider
l'inscription puis la connexion dans l'interface.

## Paiements Campay

Les demandes de paiement passent par l'Edge Function `campay-collect` afin que
les identifiants Campay restent côté serveur. Après avoir configuré et connecté
la CLI Supabase au projet, ajoutez les secrets sans les intégrer à l'application,
puis déployez la fonction :

```bash
supabase secrets set CAMPAY_USERNAME=<merchant-username> CAMPAY_PASSWORD=<merchant-password> CAMPAY_BASE_URL=https://demo.campay.net
supabase secrets set CAMPAY_WEBHOOK_SECRET=<long-random-secret>
supabase db push
supabase functions deploy campay-collect
supabase functions deploy campay-webhook --no-verify-jwt
```

Utilisez l'URL de production Campay au lieu de l'URL de démonstration lorsque le
compte marchand est prêt. Configurez dans le tableau de bord Campay l’URL de
notification `https://<project-ref>.supabase.co/functions/v1/campay-webhook?token=<long-random-secret>`.
La migration crée `campay_transactions` et la fonction SQL qui met à jour le
statut et le snapshot de cotisation une seule fois après confirmation. Les
paiements antérieurs à cette configuration ne sont pas importés automatiquement.
Pour les paiements effectués avant son déploiement, ouvrez la cotisation, utilisez
l’icône d’historique à côté du participant, puis saisissez la référence et le
montant affichés dans l’historique marchand Campay. Seul un gestionnaire peut
effectuer ce rapprochement; la référence est unique et doit être vérifiée dans
Campay avant confirmation. La date affichée correspond à la date du
rapprochement, car l’ancienne application n’avait conservé ni référence ni date
de paiement.

Les comptes Firebase existants ne sont pas transférés automatiquement : ils
doivent être migrés séparément avant la mise en production.

## Parcours de navigation couvert

- Inscription email, mot de passe et téléphone de profil; connexion email/mot de passe
- Après inscription ou connexion, redirection directe vers `/app/home`
- Créateur du groupe marqué propriétaire et administrateur; les groupes restent
    visibles uniquement par leur propriétaire jusqu'à l'ajout d'une table d'adhésions
- Créer une organisation (assistant 3 étapes) → invitation → accueil de l'organisation
- Cotisations : liste, création, détail (participants, actions)
- Tontines : liste, création, paramètres (membres, ordre de passage)
- Sanctions, Membres (liste/ajout/détail), Comptes
- Paramètres de l'organisation : Général, Fond de caisse, Liens d'invitation,
  Gestionnaires wallet, Prêts et épargne
- Profil personnel : Mon profil, Modifier, Ajouter un email, KYC, PIN

## Structure

- `lib/router.dart` — toutes les routes (go_router)
- `lib/data/` — modèles + store en mémoire
- `lib/screens/<domaine>/` — un dossier par domaine fonctionnel
- `lib/widgets/shared.dart` — composants réutilisés partout (cards, empty states, etc.)

