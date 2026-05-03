import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/property_listing_model.dart';
import '../providers/favorites_provider.dart';
import '../screens/property_details_screen.dart';

class PropertyCard extends ConsumerWidget {
  final PropertyListing property;
  final bool isGrid;

  const PropertyCard({Key? key, required this.property, this.isGrid = false}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final isFavorite = favoritesAsync.value?.contains(property.id) ?? false;
    return Padding(
      padding: isGrid ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailsScreen(propertyId: property.id, title: property.title),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Stack(
                    children: [
                      Hero(
                        tag: 'property_${property.id}',
                        child: Container(
                          height: isGrid ? 120 : 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: property.thumbnailUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(property.thumbnailUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: Colors.grey.withOpacity(0.1),
                          ),
                          child: property.thumbnailUrl == null
                              ? const Icon(Icons.home_work_outlined, size: 60, color: Colors.white24)
                              : null,
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () {
                            ref.read(favoritesNotifierProvider.notifier).toggleFavorite(property.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.redAccent : Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      if (property.isPromoted)
                        Positioned(
                          top: 15,
                          left: 15,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.star, size: 16, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'FEATURED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 15,
                        right: 15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '\$${property.pricePerMonth.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Details Section
                  Padding(
                    padding: isGrid ? const EdgeInsets.all(12.0) : const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.title,
                          style: TextStyle(
                            fontSize: isGrid ? 14 : 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.white54),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${property.city}, ${property.address}',
                                style: TextStyle(color: Colors.white54, fontSize: isGrid ? 11 : 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            _buildInfoChip(Icons.bed_outlined, '${property.bedrooms} ${isGrid ? 'B' : 'Beds'}'),
                            const SizedBox(width: 8),
                            _buildInfoChip(Icons.bathtub_outlined, '${property.bathrooms} ${isGrid ? 'B' : 'Baths'}'),
                            const Spacer(),
                            Text(
                              property.propertyType,
                              style: const TextStyle(
                                color: Colors.deepPurpleAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}
