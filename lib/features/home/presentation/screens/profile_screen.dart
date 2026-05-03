import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../providers/properties_provider.dart';
import 'add_property_screen.dart';
import 'edit_profile_screen.dart';
import 'my_properties_screen.dart';
import 'my_favorites_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value?.session?.user;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_circle_outlined, size: 80, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text('Fadlan gal xisaabtaada (Login)', style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Login Now'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.deepPurpleAccent,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    user.email ?? 'No Email',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Member since 2026',
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 40),
                  _buildProfileItem(Icons.edit, 'Edit Profile', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                  }),
                  _buildProfileItem(Icons.add_home_work_rounded, 'List a New Property', () async {
                    if (user != null) {
                      final supabase = ref.read(supabaseClientProvider);
                      final userResponse = await supabase
                          .from('users')
                          .select('is_approved')
                          .eq('id', user.id)
                          .single();
                      
                      final bool isApproved = userResponse['is_approved'] ?? false;

                      if (isApproved) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
                        ).then((_) {
                          ref.read(propertiesProvider.notifier).fetchProperties(isRefresh: true);
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Account-kaaga wali ma oggolaan Admin-ku. Fadlan sug.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  }),
                  _buildProfileItem(Icons.favorite, 'My Favorites', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyFavoritesScreen()));
                  }),
                  _buildProfileItem(Icons.home_work, 'My Properties', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPropertiesScreen()));
                  }),
                  _buildProfileItem(Icons.settings, 'Settings', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  }),
                  _buildProfileItem(Icons.help_outline, 'Help & Support', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurpleAccent),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: onTap,
      ),
    );
  }
}
