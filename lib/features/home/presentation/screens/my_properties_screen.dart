import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/properties_provider.dart';
import '../widgets/property_card.dart';
import '../../data/models/property_listing_model.dart';

class MyPropertiesScreen extends ConsumerWidget {
  const MyPropertiesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value?.session?.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Fadlan gal xisaabtaada.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: const Text('My Properties'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<PropertyListing>>(
        future: _fetchMyProperties(ref, user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white54)));
          }
          final properties = snapshot.data ?? [];
          if (properties.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_work_outlined, size: 80, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('Wali wax guri ah ma aadan soo dhigin.', style: TextStyle(color: Colors.white54)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              return PropertyCard(property: properties[index]);
            },
          );
        },
      ),
    );
  }

  Future<List<PropertyListing>> _fetchMyProperties(WidgetRef ref, String userId) async {
    final supabase = ref.read(supabaseClientProvider);
    final response = await supabase
        .from('property_listings')
        .select()
        .eq('owner_id', userId);
    
    return (response as List).map((p) => PropertyListing.fromJson(p)).toList();
  }
}
