import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final response = await supabase
      .from('categories')
      .select('name')
      .order('name', ascending: true);
  
  return List<String>.from(response.map((c) => c['name']));
});

class CategoriesNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  CategoriesNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> addCategory(String name) async {
    state = const AsyncValue.loading();
    try {
      final supabase = _ref.read(supabaseClientProvider);
      await supabase.from('categories').insert({'name': name});
      _ref.invalidate(categoriesProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteCategory(String name) async {
    state = const AsyncValue.loading();
    try {
      final supabase = _ref.read(supabaseClientProvider);
      await supabase.from('categories').delete().eq('name', name);
      _ref.invalidate(categoriesProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final categoriesNotifierProvider = StateNotifierProvider<CategoriesNotifier, AsyncValue<void>>((ref) {
  return CategoriesNotifier(ref);
});
