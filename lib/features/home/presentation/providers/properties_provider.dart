import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/models/property_listing_model.dart';

enum PropertySort { newest, priceAsc, priceDesc, promotedFirst }

class PropertyFilter {
  final String? searchQuery;
  final double? minPrice;
  final double? maxPrice;
  final String? city;
  final String? propertyType;
  final int? minBedrooms;
  final PropertySort sort;

  PropertyFilter({
    this.searchQuery,
    this.minPrice,
    this.maxPrice,
    this.city,
    this.propertyType,
    this.minBedrooms,
    this.sort = PropertySort.promotedFirst,
  });

  PropertyFilter copyWith({
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    String? city,
    String? propertyType,
    int? minBedrooms,
    PropertySort? sort,
  }) {
    return PropertyFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      city: city ?? this.city,
      propertyType: propertyType ?? this.propertyType,
      minBedrooms: minBedrooms ?? this.minBedrooms,
      sort: sort ?? this.sort,
    );
  }
}

final propertyFilterProvider = StateProvider<PropertyFilter>((ref) => PropertyFilter());

final propertiesProvider = StateNotifierProvider<PropertiesNotifier, AsyncValue<List<PropertyListing>>>((ref) {
  final filter = ref.watch(propertyFilterProvider);
  return PropertiesNotifier(ref.watch(supabaseClientProvider), filter);
});

class PropertiesNotifier extends StateNotifier<AsyncValue<List<PropertyListing>>> {
  final SupabaseClient _supabase;
  final PropertyFilter _filter;
  static const int _pageSize = 10;
  int _currentPage = 0;
  bool _hasMore = true;

  PropertiesNotifier(this._supabase, this._filter) : super(const AsyncValue.loading()) {
    fetchProperties();
  }

  bool get hasMore => _hasMore;

  Future<void> fetchProperties({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 0;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (!_hasMore) return;

    try {
      final from = _currentPage * _pageSize;
      final to = from + _pageSize - 1;

      dynamic query = _supabase.from('properties').select();

      // Apply Filters
      if (_filter.searchQuery != null && _filter.searchQuery!.isNotEmpty) {
        query = query.or('title.ilike.%${_filter.searchQuery}%,description.ilike.%${_filter.searchQuery}%');
      }
      if (_filter.minPrice != null) {
        query = query.gte('price_per_month', _filter.minPrice!);
      }
      if (_filter.maxPrice != null) {
        query = query.lte('price_per_month', _filter.maxPrice!);
      }
      if (_filter.city != null && _filter.city!.isNotEmpty) {
        query = query.eq('city', _filter.city!);
      }
      if (_filter.propertyType != null && _filter.propertyType!.isNotEmpty) {
        query = query.eq('property_type', _filter.propertyType!);
      }
      if (_filter.minBedrooms != null) {
        query = query.gte('bedrooms', _filter.minBedrooms!);
      }

      // Apply Sorting
      switch (_filter.sort) {
        case PropertySort.promotedFirst:
          query = query.order('is_promoted', ascending: false).order('created_at', ascending: false);
          break;
        case PropertySort.newest:
          query = query.order('created_at', ascending: false);
          break;
        case PropertySort.priceAsc:
          query = query.order('price_per_month', ascending: true);
          break;
        case PropertySort.priceDesc:
          query = query.order('price_per_month', ascending: false);
          break;
      }

      final response = await query.range(from, to);

      final newProperties = (response as List).map((e) => PropertyListing.fromJson(e)).toList();

      if (newProperties.length < _pageSize) {
        _hasMore = false;
      }

      if (isRefresh || state.value == null) {
        state = AsyncValue.data(newProperties);
      } else {
        state = AsyncValue.data([...state.value!, ...newProperties]);
      }

      _currentPage++;
    } catch (e, stack) {
      if (state.value == null) {
        state = AsyncValue.error(e, stack);
      }
    }
  }
}
