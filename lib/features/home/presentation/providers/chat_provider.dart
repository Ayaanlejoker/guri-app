import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';
import 'package:rxdart/rxdart.dart';

final chatRoomsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value([]);

  final buyerStream = supabase
      .from('chat_rooms')
      .stream(primaryKey: ['id'])
      .eq('buyer_id', user.id);

  final sellerStream = supabase
      .from('chat_rooms')
      .stream(primaryKey: ['id'])
      .eq('seller_id', user.id);

  return CombineLatestStream.combine2<List<Map<String, dynamic>>, List<Map<String, dynamic>>, List<Map<String, dynamic>>>(
    buyerStream,
    sellerStream,
    (buyers, sellers) {
      final all = [...buyers, ...sellers];
      final ids = <String>{};
      final unique = all.where((room) => ids.add(room['id'])).toList();
      unique.sort((a, b) => b['created_at'].compareTo(a['created_at']));
      return unique;
    },
  ).asBroadcastStream();
});

final messagesProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, chatId) {
  final supabase = ref.watch(supabaseClientProvider);
  
  return supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('chat_id', chatId)
      .order('created_at', ascending: true)
      .map((data) => data);
});

class ChatNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  ChatNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<String> createOrGetChat(String propertyId, String sellerId) async {
    final supabase = _ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Login required');

    try {
      // Check if exists
      final existing = await supabase
          .from('chat_rooms')
          .select()
          .eq('property_id', propertyId)
          .eq('buyer_id', user.id)
          .maybeSingle();

      if (existing != null) return existing['id'];

      // Create new
      final response = await supabase
          .from('chat_rooms')
          .insert({
            'property_id': propertyId,
            'buyer_id': user.id,
            'seller_id': sellerId,
          })
          .select()
          .single();
      
      return response['id'];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendMessage(String chatId, String content) async {
    final supabase = _ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // 1. Insert message
    await supabase.from('messages').insert({
      'chat_id': chatId,
      'sender_id': user.id,
      'content': content,
    });

    // 2. Notify receiver
    try {
      final room = await supabase
          .from('chat_rooms')
          .select('buyer_id, seller_id, properties(title)')
          .eq('id', chatId)
          .single();
      
      final receiverId = room['buyer_id'] == user.id ? room['seller_id'] : room['buyer_id'];
      final propertyTitle = room['properties']['title'] ?? 'Guri';

      await supabase.from('notifications').insert({
        'user_id': receiverId,
        'title': 'Fariin Cusub',
        'message': 'Waxaad fariin cusub ka heshay qof xiisaynaya "$propertyTitle".',
        'type': 'new_message',
        'related_id': chatId,
      });
    } catch (e) {
      print('Notification error: $e');
    }
  }
}

final chatNotifierProvider = StateNotifierProvider<ChatNotifier, AsyncValue<void>>((ref) {
  return ChatNotifier(ref);
});
