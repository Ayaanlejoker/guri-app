import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// IMPORTANT: Service Role Key should never be used in a public app.
// This is used here strictly for the Super Admin dashboard prototype.
const _supabaseUrl = 'https://voohzzpoldchogafchip.supabase.co';
const _serviceRoleKey = 'sb_secret_7mF1aPKihd3DiC8j8i-zog_zr94sF84';

final adminSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseClient(_supabaseUrl, _serviceRoleKey);
});
