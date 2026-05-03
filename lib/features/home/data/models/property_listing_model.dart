class PropertyListing {
  final String id;
  final String title;
  final double pricePerMonth;
  final String address;
  final String city;
  final String propertyType;
  final int bedrooms;
  final int bathrooms;
  final String? thumbnailUrl;
  final List<String> imageUrls;
  final bool isPromoted;

  PropertyListing({
    required this.id,
    required this.title,
    required this.pricePerMonth,
    required this.address,
    required this.city,
    required this.propertyType,
    required this.bedrooms,
    required this.bathrooms,
    this.thumbnailUrl,
    this.imageUrls = const [],
    required this.isPromoted,
  });

  factory PropertyListing.fromJson(Map<String, dynamic> json) {
    return PropertyListing(
      id: json['id'],
      title: json['title'],
      pricePerMonth: (json['price_per_month'] as num).toDouble(),
      address: json['address'],
      city: json['city'],
      propertyType: json['property_type'] ?? 'Apartment',
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      thumbnailUrl: json['thumbnail_url'],
      imageUrls: json['image_urls'] != null ? List<String>.from(json['image_urls']) : [],
      isPromoted: json['is_promoted'] ?? false,
    );
  }
}
