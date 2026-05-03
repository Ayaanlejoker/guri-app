import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/properties_provider.dart';

class FilterPanel extends ConsumerStatefulWidget {
  const FilterPanel({Key? key}) : super(key: key);

  @override
  ConsumerState<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends ConsumerState<FilterPanel> {
  late TextEditingController _searchController;
  late TextEditingController _cityController;
  String? _propertyType;
  int? _minBedrooms;
  late PropertySort _sort;
  late RangeValues _currentRange;

  final List<String> _propertyTypes = ['Apartment', 'House', 'Villa', 'Commercial'];

  @override
  void initState() {
    super.initState();
    final filter = ref.read(propertyFilterProvider);
    _searchController = TextEditingController(text: filter.searchQuery);
    _cityController = TextEditingController(text: filter.city);
    _propertyType = filter.propertyType;
    _minBedrooms = filter.minBedrooms;
    _sort = filter.sort;
    _currentRange = RangeValues(
      filter.minPrice ?? 0,
      filter.maxPrice ?? 10000,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final newFilter = PropertyFilter(
      searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      minPrice: _currentRange.start,
      maxPrice: _currentRange.end,
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      propertyType: _propertyType,
      minBedrooms: _minBedrooms,
      sort: _sort,
    );

    ref.read(propertyFilterProvider.notifier).state = newFilter;
    ref.read(propertiesProvider.notifier).fetchProperties(isRefresh: true);
    Navigator.pop(context);
  }

  void _clearFilter() {
    ref.read(propertyFilterProvider.notifier).state = PropertyFilter();
    ref.read(propertiesProvider.notifier).fetchProperties(isRefresh: true);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filters & Sorting', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: _clearFilter,
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const Divider(),
            
            // Search
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(labelText: 'Search title...', prefixIcon: Icon(Icons.search)),
            ),
            const SizedBox(height: 12),

            // Sorting
            const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<PropertySort>(
              isExpanded: true,
              value: _sort,
              items: const [
                DropdownMenuItem(value: PropertySort.promotedFirst, child: Text('Promoted First')),
                DropdownMenuItem(value: PropertySort.newest, child: Text('Newest')),
                DropdownMenuItem(value: PropertySort.priceAsc, child: Text('Price: Low to High')),
                DropdownMenuItem(value: PropertySort.priceDesc, child: Text('Price: High to Low')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _sort = val);
              },
            ),
            const SizedBox(height: 12),

            // Price Range
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Price Range', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('\$${_currentRange.start.round()} - \$${_currentRange.end.round()}', 
                  style: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            RangeSlider(
              values: _currentRange,
              min: 0,
              max: 10000,
              divisions: 100,
              activeColor: Colors.deepPurpleAccent,
              inactiveColor: Colors.white12,
              labels: RangeLabels(
                '\$${_currentRange.start.round()}',
                '\$${_currentRange.end.round()}',
              ),
              onChanged: (values) {
                setState(() => _currentRange = values);
              },
            ),
            const SizedBox(height: 12),

            // City
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 12),

            // Property Type
            const Text('Property Type', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String?>(
              isExpanded: true,
              value: _propertyType,
              hint: const Text('Any Type'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any Type')),
                ..._propertyTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))),
              ],
              onChanged: (val) => setState(() => _propertyType = val),
            ),
            const SizedBox(height: 12),

            // Bedrooms
            const Text('Minimum Bedrooms', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<int?>(
              isExpanded: true,
              value: _minBedrooms,
              hint: const Text('Any'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Any')),
                DropdownMenuItem(value: 1, child: Text('1+')),
                DropdownMenuItem(value: 2, child: Text('2+')),
                DropdownMenuItem(value: 3, child: Text('3+')),
                DropdownMenuItem(value: 4, child: Text('4+')),
              ],
              onChanged: (val) => setState(() => _minBedrooms = val),
            ),
            const SizedBox(height: 24),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilter,
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
