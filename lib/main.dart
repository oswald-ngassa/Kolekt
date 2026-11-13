import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/store.dart';
import 'router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ttdilagygcxpmihjoubv.supabase.co',
  );
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_qI9MXwpWovrVXgRy22Fsmg_u3U8dBZ3',
  );

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    ).timeout(const Duration(seconds: 8));

    if (Supabase.instance.client.auth.currentSession != null) {
      try {
        await AppStore.instance.loadOrganizations();
      } catch (error) {
        debugPrint('Chargement des groupes Supabase impossible: $error');
      }
    }
  } catch (error) {
    debugPrint('Initialisation Supabase impossible: $error');
  }

  runApp(const KolektApp());
}

class _StartupErrorApp extends StatelessWidget {
  final String message;

  const _StartupErrorApp({required this.message});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Kolekt',
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Impossible de démarrer Kolekt',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );
}

class KolektApp extends StatelessWidget {
  const KolektApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Kolekt',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(AppStore.instance.themeMode),
          routerConfig: appRouter,
        );
      },
    );
  }
}
