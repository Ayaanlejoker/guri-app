import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_provider.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(ref.read(supabaseClientProvider));
});

class AnalyticsService {
  final SupabaseClient _supabase;

  AnalyticsService(this._supabase);

  Future<void> logEvent({
    required String propertyId,
    required String eventType, // 'view', 'call_click', 'whatsapp_click'
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('property_analytics').insert({
        'property_id': propertyId,
        'user_id': user.id,
        'event_type': eventType,
      });
    } catch (e) {
      // Analytics errors shouldn't crash the app, so we just catch and optionally log them
      print('Analytics error: $e');
    }
  }
}
