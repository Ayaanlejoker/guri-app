import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/models/property_listing_model.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../providers/properties_provider.dart';
import '../providers/categories_provider.dart';
import '../widgets/property_card.dart';
import '../widgets/filter_panel.dart';
import 'add_property_screen.dart';
import 'admin_dashboard_screen.dart';
import 'profile_screen.dart';
import 'property_map_screen.dart';
import 'inbox_screen.dart';
import 'notifications_screen.dart';
import '../providers/notifications_provider.dart';
import '../widgets/property_card_shimmer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(propertiesProvider.notifier);
      if (notifier.hasMore) {
        notifier.fetchProperties();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertiesState = ref.watch(propertiesProvider);
    final authState = ref.watch(authStateProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final user = authState.value?.session?.user;

    final List<Widget> pages = [
      _buildHomeContent(user, propertiesState, categoriesAsync),
      const InboxScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.deepPurpleAccent,
          unselectedItemColor: Colors.white38,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Inbox'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(User? user, AsyncValue<List<PropertyListing>> propertiesState, AsyncValue<List<String>> categoriesAsync) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.05),
              title: const Text(
                'Guri Kaal',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.map_outlined, color: Colors.white70),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PropertyMapScreen())),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final unreadCount = ref.watch(unreadNotificationsCountProvider);
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none, color: Colors.white70),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                unreadCount > 9 ? '9+' : unreadCount.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.tune, color: Colors.white70),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: const Color(0xFF1B1B2F),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (_) => const FilterPanel(),
                    );
                  },
                ),
                if (user == null)
                  IconButton(
                    icon: const Icon(Icons.login_rounded, color: Colors.deepPurpleAccent),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                if (user != null)
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0C29), Color(0xFF1B1B2F)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 100), // Space for glassy AppBar
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) {
                    ref.read(propertyFilterProvider.notifier).update((s) => s.copyWith(searchQuery: val));
                  },
                  decoration: const InputDecoration(
                    hintText: 'Raadi guri, xaafad...',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // City Filter Row
            _buildFilterRow(
              title: 'Magaalooyinka',
              items: ['Dhammaan', 'Muqdisho', 'Hargeysa', 'Borama', 'Garowe', 'Kismaayo'],
              selectedItem: ref.watch(propertyFilterProvider).city ?? 'Dhammaan',
              onSelected: (val) {
                ref.read(propertyFilterProvider.notifier).update((s) => s.copyWith(city: val == 'Dhammaan' ? '' : val));
              },
            ),
            
            // Category Filter Row
            categoriesAsync.when(
              data: (categories) => _buildFilterRow(
                title: 'Noocyada',
                items: ['Dhammaan', ...categories],
                selectedItem: ref.watch(propertyFilterProvider).propertyType ?? 'Dhammaan',
                onSelected: (val) {
                  ref.read(propertyFilterProvider.notifier).update((s) => s.copyWith(propertyType: val == 'Dhammaan' ? '' : val));
                },
                isCategory: true,
              ),
              loading: () => const SizedBox(height: 50, child: Center(child: LinearProgressIndicator())),
              error: (e, s) => const SizedBox.shrink(),
            ),

            Expanded(
              child: propertiesState.when(
                data: (properties) {
                  final featuredProperties = properties.where((p) => p.isPromoted).toList();
                  final normalProperties = properties;

                  return RefreshIndicator(
                    onRefresh: () => ref.read(propertiesProvider.notifier).fetchProperties(isRefresh: true),
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        // 1. Featured Slider
                        if (featuredProperties.isNotEmpty)
                          SliverToBoxAdapter(
                            child: _buildFeaturedSlider(featuredProperties),
                          ),

                        // 2. Section Title
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Guryaha Yaala',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${normalProperties.length} la helay',
                                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 3. Normal Grid
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.72,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final property = normalProperties[index];
                                return PropertyCard(property: property, isGrid: true);
                              },
                              childCount: normalProperties.length,
                            ),
                          ),
                        ),

                        // 4. Loader
                        if (ref.read(propertiesProvider.notifier).hasMore)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)),
                            ),
                          ),
                        
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  );
                },
                loading: () => CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (_, __) => const PropertyCardShimmer(isGrid: true),
                          childCount: 6,
                        ),
                      ),
                    ),
                  ],
                ),
                error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white54))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSlider(List<PropertyListing> properties) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Featured Properties', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final p = properties[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: PropertyCard(property: p, isGrid: true),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow({
    required String title,
    required List<String> items,
    required String selectedItem,
    required Function(String) onSelected,
    bool isCategory = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = selectedItem == item || (selectedItem == '' && item == 'Dhammaan');
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(item),
                  selected: isSelected,
                  onSelected: (selected) => onSelected(item),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  selectedColor: Colors.deepPurpleAccent,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  showCheckmark: false,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
