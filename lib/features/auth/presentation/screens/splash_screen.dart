import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63)],
          ),
        ),
        child: authState.when(
          data: (state) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Always navigate to HomeScreen to make the app public
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            });
            return _buildSplashContent();
          },
          loading: () => _buildSplashContent(),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildSplashContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/splash.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback in case the image is missing
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F0C29), Color(0xFF302B63)],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home_work_rounded, size: 100, color: Colors.white),
                    SizedBox(height: 24),
                    Text(
                      'GURI KAAL',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        // Optional: Add a small loading indicator at the bottom
        const Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}
