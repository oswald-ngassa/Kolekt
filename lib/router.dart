import 'package:go_router/go_router.dart';
import 'data/models.dart';
import 'data/store.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/organizations/new_organization_screen.dart';
import 'screens/organizations/join_organization_screen.dart';
import 'screens/cotisations/new_cotisation_screen.dart';
import 'screens/cotisations/cotisation_detail_screen.dart';
import 'screens/tontines/new_tontine_screen.dart';
import 'screens/tontines/tontine_params_screen.dart';
import 'screens/sanctions/sanctions_screen.dart';
import 'screens/members/members_screen.dart';
import 'screens/members/new_member_screen.dart';
import 'screens/members/member_detail_screen.dart';
import 'screens/accounts/comptes_screen.dart';
import 'screens/org_settings/org_settings_screen.dart';
import 'screens/org_settings/fond_de_caisse_screen.dart';
import 'screens/org_settings/general_screen.dart';
import 'screens/org_settings/invite_links_screen.dart';
import 'screens/org_settings/wallet_managers_screen.dart';
import 'screens/org_settings/prets_epargne_screen.dart';
import 'screens/org_settings/misc_screens.dart';
import 'screens/profile/mon_profil_screen.dart';
import 'screens/profile/mes_associations_screen.dart';
import 'screens/profile/modifier_profil_screen.dart';
import 'screens/profile/ajouter_email_screen.dart';
import 'screens/profile/kyc_screen.dart';

/// Retrouve une organisation par id dans le store en mémoire (frontend only).
Organization _org(String id) =>
    AppStore.instance.organizations.firstWhere((o) => o.id == id);

final appRouter = GoRouter(
  initialLocation: '/sign-in',
  routes: [
    GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
    GoRoute(
        path: '/create-account',
        builder: (_, __) => const SignInScreen(isSignUp: true)),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const MonProfilScreen()),
    GoRoute(
        path: '/profile/organizations',
        builder: (_, __) => const MesAssociationsScreen()),
    GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const ModifierProfilScreen()),
    GoRoute(
        path: '/profile/add-email',
        builder: (_, __) => const AjouterEmailScreen()),
    GoRoute(path: '/profile/kyc', builder: (_, __) => const KycScreen()),
    GoRoute(path: '/app/home', builder: (_, __) => const HomeShell()),
    GoRoute(
        path: '/organizations/new',
        builder: (_, __) => const NewOrganizationScreen()),
    GoRoute(
      path: '/organizations/join',
      builder: (_, __) => const JoinOrganizationScreen(),
    ),
    GoRoute(
      path: '/organizations/:orgId/edit',
      builder: (_, state) => NewOrganizationScreen(
          organization: _org(state.pathParameters['orgId']!)),
    ),
    GoRoute(
      path: '/organizations/:orgId/cotisations/new',
      builder: (_, state) =>
          NewCotisationScreen(org: _org(state.pathParameters['orgId']!)),
    ),
    GoRoute(
      path: '/organizations/:orgId/cotisations/:cid',
      builder: (_, state) {
        final org = _org(state.pathParameters['orgId']!);
        final c = org.cotisations
            .firstWhere((c) => c.id == state.pathParameters['cid']);
        return CotisationDetailScreen(org: org, cotisation: c);
      },
    ),
    GoRoute(
      path: '/organizations/:orgId/tontines/new',
      builder: (_, state) =>
          NewTontineScreen(org: _org(state.pathParameters['orgId']!)),
    ),
    GoRoute(
      path: '/organizations/:orgId/tontines/:tid/params',
      builder: (_, state) {
        final org = _org(state.pathParameters['orgId']!);
        final t =
            org.tontines.firstWhere((t) => t.id == state.pathParameters['tid']);
        return TontineParamsScreen(org: org, tontine: t);
      },
    ),
    GoRoute(
      path: '/organizations/:orgId/sanctions',
      builder: (_, state) =>
          SanctionsScreen(org: _org(state.pathParameters['orgId']!)),
    ),
    GoRoute(
      path: '/organizations/:orgId/members',
      builder: (_, state) =>
          MembersScreen(org: _org(state.pathParameters['orgId']!)),
    ),
    GoRoute(
      path: '/organizations/:orgId/members/new',
      builder: (_, state) =>
          NewMemberScreen(org: _org(state.pathParameters['orgId']!)),
    ),
    GoRoute(
      path: '/organizations/:orgId/members/:mid',
      builder: (_, state) {
        final org = _org(state.pathParameters['orgId']!);
        final m =
            org.membres.firstWhere((m) => m.id == state.pathParameters['mid']);
        return MemberDetailScreen(org: org, member: m);
      },
    ),
    GoRoute(
      path: '/organizations/:orgId/comptes',
      builder: (_, state) =>
          ComptesScreen(org: _org(state.pathParameters['orgId']!)),
    ),
    GoRoute(
      path: '/organizations/:orgId/sessions',
      builder: (_, state) =>
          SessionsScreen(org: _org(state.pathParameters['orgId']!)),
    ),
    GoRoute(
      path: '/organizations/:orgId/statement',
      builder: (_, state) =>
          StatementScreen(org: _org(state.pathParameters['orgId']!)),
    ),
    GoRoute(
      path: '/organizations/:orgId/settings',
      builder: (_, state) =>
          OrgSettingsScreen(org: _org(state.pathParameters['orgId']!)),
    ),
    GoRoute(
      path: '/organizations/:orgId/fond-de-caisse',
      builder: (_, state) =>
          FondDeCaisseScreen(org: _org(state.pathParameters['orgId']!)),
    ),
    GoRoute(
      path: '/organizations/:orgId/general',
      builder: (_, state) =>
          GeneralScreen(org: _org(state.pathParameters['orgId']!)),
    ),
    GoRoute(
      path: '/organizations/:orgId/invite-links',
      builder: (_, state) =>
          InviteLinksScreen(org: _org(state.pathParameters['orgId']!)),
    ),
    GoRoute(
      path: '/organizations/:orgId/wallet-managers',
      builder: (_, state) =>
          WalletManagersScreen(org: _org(state.pathParameters['orgId']!)),
    ),
    GoRoute(
      path: '/organizations/:orgId/prets-epargne',
      builder: (_, state) =>
          PretsEpargneScreen(org: _org(state.pathParameters['orgId']!)),
    ),
  ],
);
