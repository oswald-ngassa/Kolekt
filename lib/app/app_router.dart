import 'package:flutter/material.dart';

import '../screens/create_group_screen.dart';
import '../screens/group_details_screen.dart';
import '../screens/home_shell.dart';
import '../screens/invite_screen.dart';
import '../screens/name_screen.dart';
import '../screens/otp_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/profile/mon_profil_screen.dart';
import '../screens/service_chooser_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/sign_in_screen.dart';
import '../screens/transaction_history_screen.dart';
import '../services/auth_service.dart';

class AppRoutes {
  static const authSignIn = '/auth/sign-in';
  static const authOtp = '/auth/otp';
  static const authName = '/auth/name';
  static const serviceChooser = '/service-chooser';
  static const homeShell = '/home-shell';
  static const createGroup = '/group/create';
  static const groupDetails = '/group/details';
  static const payment = '/payment';
  static const transactionHistory = '/transactions';
  static const profile = '/profile';
  static const invite = '/invite';
  static const settings = '/settings';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.authSignIn:
        final args = settings.arguments is Map ? settings.arguments as Map : {};
        final isSignUp = args['isSignUp'] as bool? ?? false;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SignInScreen(isSignUp: isSignUp),
        );

      case AppRoutes.authOtp:
        final args = settings.arguments is Map ? settings.arguments as Map : {};
        final sendResult = args['sendResult'] as OtpSendResult?;
        final authService =
            args['authService'] as AuthService? ?? AuthService();

        if (sendResult == null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const _InvalidRouteScreen(
              title: 'Erreur de route',
              message: 'Le code OTP n’a pas été fourni à la route.',
            ),
          );
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => OtpScreen(
            sendResult: sendResult,
            authService: authService,
            profile:
                Map<String, dynamic>.from(args['profile'] as Map? ?? const {}),
          ),
        );

      case AppRoutes.authName:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const NameScreen(),
        );

      case AppRoutes.serviceChooser:
        final args = settings.arguments is Map ? settings.arguments as Map : {};
        final name = args['name'] as String? ?? 'nOVa';
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ServiceChooserScreen(name: name),
        );

      case AppRoutes.homeShell:
        final args = settings.arguments is Map ? settings.arguments as Map : {};
        final serviceName = args['serviceName'] as String? ?? 'nOVa';
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => HomeShell(serviceName: serviceName),
        );

      case AppRoutes.createGroup:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CreateGroupScreen(),
        );

      case AppRoutes.groupDetails:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const GroupDetailsScreen(),
        );

      case AppRoutes.payment:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PaymentScreen(),
        );

      case AppRoutes.transactionHistory:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const TransactionHistoryScreen(),
        );

      case AppRoutes.profile:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MonProfilScreen(),
        );

      case AppRoutes.invite:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const InviteScreen(),
        );

      case AppRoutes.settings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SettingsScreen(),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SignInScreen(),
        );
    }
  }
}

class _InvalidRouteScreen extends StatelessWidget {
  final String title;
  final String message;

  const _InvalidRouteScreen({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(message),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.authSignIn),
                child: const Text('Retour à l’accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
