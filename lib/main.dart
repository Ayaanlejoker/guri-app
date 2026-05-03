import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'core/services/push_notification_service.dart';
import 'core/providers/supabase_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://voohzzpoldchogafchip.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvb2h6enBvbGRjaG9nYWZjaGlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcyOTUzNzUsImV4cCI6MjA5Mjg3MTM3NX0.uapUV0SAblKzY8h3m0gnBsvXyewOG5cyb1peFw9bjkQ',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize Push Notifications
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PushNotificationService.initialize();
      final supabase = ref.read(supabaseClientProvider);
      if (supabase.auth.currentUser != null) {
        await PushNotificationService.updateTokenInDatabase(supabase);
      }
    });

    return MaterialApp(
      title: 'Guri Kaal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0C29),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
