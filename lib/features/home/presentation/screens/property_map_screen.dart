import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/properties_provider.dart';
import '../widgets/property_card.dart';

class PropertyMapScreen extends ConsumerWidget {
  const PropertyMapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesState = ref.watch(propertiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: Stack(
        children: [
          // MAP PLACEHOLDER (Since Google Maps needs setup)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=1000'),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 100, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('Map View Coming Soon', style: TextStyle(color: Colors.white70, fontSize: 18)),
                  Text('Configure Google Maps API to see markers', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          ),

          // Bottom Slider for Properties
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            height: 160,
            child: propertiesState.when(
              data: (properties) => ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: properties.length,
                itemBuilder: (context, index) {
                  final p = properties[index];
                  return Container(
                    width: 320,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: PropertyCard(property: p),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const SizedBox.shrink(),
            ),
          ),

          // Back Button
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
