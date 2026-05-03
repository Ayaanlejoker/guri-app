import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  Future<void> _launchEmail() async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: 'support@gurikaal.com',
      query: 'subject=App Support Request',
    );
    if (await canLaunchUrl(params)) {
      await launchUrl(params);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.support_agent, size: 80, color: Colors.deepPurpleAccent),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Sidee baan kuu caawin karnaa?',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Waxaan halkan u joognaa inaan ku caawino 24/7',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 40),
            
            _buildSupportCard(
              Icons.email_outlined, 
              'Email Us', 
              'support@gurikaal.com', 
              _launchEmail
            ),
            const SizedBox(height: 16),
            _buildSupportCard(
              Icons.phone_outlined, 
              'Call Support', 
              '+252 61xxxxxxx', 
              () {}
            ),
            const SizedBox(height: 16),
            _buildSupportCard(
              Icons.question_answer_outlined, 
              'FAQs', 
              'Common questions answered', 
              () {}
            ),
            
            const SizedBox(height: 40),
            const Text(
              'About Guri Kaal',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Guri Kaal waa carwada ugu weyn ee guryaha kireysan ee Soomaaliya. Waxaan kuu fududeyneynaa inaad hesho guri raaxo leh oo ku habboon baahidaada.',
              style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.deepPurpleAccent),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
