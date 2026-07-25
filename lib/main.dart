import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'providers/settings_provider.dart';
import 'providers/user_role_provider.dart';
import 'screens/splash_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://elkkyxoneoylempejnjk.supabase.co',
      publishableKey:
          'sb_publishable_6oUCJ4v_ZNYchXxPqU5nag_1gJxY7h2', // TODO: Add your Supabase Anon Key
    );
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }

  // Auto-login anonymously so blind users don't need to do anything
  await SupabaseService().ensureLoggedIn();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => UserRoleProvider()..init()),
      ],
      child: const NourApp(),
    ),
  );
}

class NourApp extends StatelessWidget {
  const NourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نور',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Enforce large text scaling for accessibility
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.1)),
          child: child!,
        );
      },
    );
  }
}
