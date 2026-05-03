import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Account'),
          _buildSettingsTile(Icons.notifications_none, 'Notifications', 'Manage app alerts', () {}),
          _buildSettingsTile(Icons.lock_outline, 'Privacy', 'Control your data', () {}),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Preferences'),
          _buildSettingsTile(Icons.dark_mode_outlined, 'Dark Mode', 'Automatic', null, trailing: Switch(value: true, onChanged: (v){})),
          _buildSettingsTile(Icons.language, 'Language', 'English (Somali coming soon)', () {}),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Legal'),
          _buildSettingsTile(Icons.description_outlined, 'Terms of Service', '', () {}),
          _buildSettingsTile(Icons.privacy_tip_outlined, 'Privacy Policy', '', () {}),
          
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, VoidCallback? onTap, {Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: onTap,
      ),
    );
  }
}
