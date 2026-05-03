import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';

class PromotePropertyScreen extends ConsumerStatefulWidget {
  final String propertyId;
  const PromotePropertyScreen({Key? key, required this.propertyId}) : super(key: key);

  @override
  ConsumerState<PromotePropertyScreen> createState() => _PromotePropertyScreenState();
}

class _PromotePropertyScreenState extends ConsumerState<PromotePropertyScreen> {
  int _selectedDays = 1;
  bool _isLoading = false;

  Future<void> _promote() async {
    setState(() => _isLoading = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      
      // Calculate end date
      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: _selectedDays));
      
      await supabase.from('promotions').insert({
        'property_id': widget.propertyId,
        'discount_percentage': 0.0,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'is_active': false, // Not active until admin approves
        'status': 'pending',
      });

      // Notify Super Admins about the promotion request
      try {
        final superAdmins = await supabase.from('users').select('id').eq('role', 'super_admin');
        for (final admin in superAdmins) {
          await supabase.from('notifications').insert({
            'user_id': admin['id'],
            'title': 'Promotion Request',
            'message': 'Guri cusub ayaa loo soo codsaday Promotion (Boost). Fadlan hubi lacagta oo ansixi.',
            'type': 'promotion_request',
            'related_id': widget.propertyId,
          });
        }
      } catch (e) {
        print('Notification error: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Codsigaaga waa nala soo gaadhay. Admin-ka ayaa ansixin doona marka lacagta la xaqiijiyo.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promote Property')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Promotion Duration:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildOption(1, '1 Day Boost', 'Appear at the top for 24 hours', Colors.blue),
            const SizedBox(height: 12),
            _buildOption(3, '3 Days Boost', 'Appear at the top for 3 days', Colors.orange),
            const SizedBox(height: 12),
            _buildOption(7, '7 Days Featured', 'Premium visibility for a whole week', Colors.purple),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _promote,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm Promotion', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(int days, String title, String subtitle, Color color) {
    final isSelected = _selectedDays == days;
    return InkWell(
      onTap: () => setState(() => _selectedDays = days),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? color : Colors.black)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
