import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';

final favoritesProvider = FutureProvider<List<String>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final response = await supabase
      .from('favorites')
      .select('property_id')
      .eq('user_id', user.id);
  
  return List<String>.from(response.map((f) => f['property_id']));
});

class FavoritesNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  FavoritesNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> toggleFavorite(String propertyId) async {
    final supabase = _ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final favorites = _ref.read(favoritesProvider).value ?? [];
      final isFav = favorites.contains(propertyId);

      if (isFav) {
        await supabase
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('property_id', propertyId);
      } else {
        await supabase
            .from('favorites')
            .insert({'user_id': user.id, 'property_id': propertyId});
      }
      _ref.invalidate(favoritesProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final favoritesNotifierProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<void>>((ref) {
  return FavoritesNotifier(ref);
});
