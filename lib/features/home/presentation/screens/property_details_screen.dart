import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/analytics_service.dart';
import 'promote_property_screen.dart';
import '../providers/properties_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_room_screen.dart';
import 'chat_screen.dart';

class PropertyDetailsScreen extends ConsumerStatefulWidget {
  final String propertyId;
  final String title;

  const PropertyDetailsScreen({Key? key, required this.propertyId, required this.title}) : super(key: key);

  @override
  ConsumerState<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends ConsumerState<PropertyDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _propertyDetails;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final response = await supabase
          .from('properties')
          .select('*, property_media(media_url), users(phone_number, whatsapp_number, first_name)')
          .eq('id', widget.propertyId)
          .single();

      setState(() {
        _propertyDetails = response;
        _isLoading = false;
      });

      // Track property view
      ref.read(analyticsServiceProvider).logEvent(
        propertyId: widget.propertyId,
        eventType: 'view',
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _launchPhone(String phone) async {
    // Track call click
    ref.read(analyticsServiceProvider).logEvent(
      propertyId: widget.propertyId,
      eventType: 'call_click',
    );

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open dialer')));
      }
    }
  }

  Future<void> _launchWhatsApp(String phone, String title) async {
    // Track whatsapp click
    ref.read(analyticsServiceProvider).logEvent(
      propertyId: widget.propertyId,
      eventType: 'whatsapp_click',
    );

    final message = Uri.encodeComponent('Hello I am interested in $title');
    final formattedPhone = phone.replaceAll(RegExp(r'[^\d+]'), ''); // clean phone
    final uri = Uri.parse('https://wa.me/$formattedPhone?text=$message');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _propertyDetails != null && 
        ref.read(supabaseClientProvider).auth.currentUser?.id == _propertyDetails!['owner_id'];
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: _buildBody(),
      bottomNavigationBar: _propertyDetails != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_propertyDetails == null) {
      return const Center(child: Text('Property not found'));
    }

    final data = _propertyDetails!;
    final media = data['property_media'] as List;
    final List<String> images = media.map((m) => m['media_url'] as String).toList();
    
    // Add thumbnail if it's not in the list
    final thumb = data['thumbnail_url'];
    if (thumb != null && !images.contains(thumb)) {
      images.insert(0, thumb);
    }

    final PageController pageController = PageController();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Carousel with Indicators
          Stack(
            children: [
              if (images.isNotEmpty)
                Hero(
                  tag: 'property_${widget.propertyId}',
                  child: SizedBox(
                    height: 300,
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                )
              else
                Hero(
                  tag: 'property_${widget.propertyId}',
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.white.withOpacity(0.05),
                    child: const Icon(Icons.home_work_outlined, size: 80, color: Colors.white24),
                  ),
                ),
              
              // Indicators
              if (images.length > 1)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ListenableBuilder(
                      listenable: pageController,
                      builder: (context, child) {
                        int current = pageController.hasClients ? pageController.page?.round() ?? 0 : 0;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: current == index ? 24 : 8,
                              decoration: BoxDecoration(
                                color: current == index ? Colors.deepPurpleAccent : Colors.white70,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ),
              
              // Back Button Overlay
              Positioned(
                top: 40,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black38,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${data['price_per_month']}/mo',
                  style: const TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.deepPurpleAccent,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data['title'],
                  style: const TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: Colors.white.withOpacity(0.5), size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${data['address']}, ${data['city']}',
                        style: TextStyle(
                          fontSize: 16, 
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white10),
                const SizedBox(height: 24),
                
                // Features
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildFeature(Icons.bed_outlined, '${data['bedrooms']} Beds'),
                      _buildFeature(Icons.bathtub_outlined, '${data['bathrooms']} Baths'),
                      if (data['square_meters'] != null)
                        _buildFeature(Icons.square_foot_outlined, '${data['square_meters']} sqm'),
                      _buildFeature(Icons.apartment_outlined, data['property_type'] ?? 'Apartment'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Description
                const Text(
                  'Description', 
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )
                ),
                const SizedBox(height: 12),
                Text(
                  data['description'] ?? 'No description provided.',
                  style: TextStyle(
                    fontSize: 16, 
                    height: 1.6,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 120), // extra spacing for bottom bar
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurpleAccent, size: 28),
        const SizedBox(height: 8),
        Text(
          text, 
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          )
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final data = _propertyDetails!;
    final user = data['users'];
    final phone = user != null ? user['phone_number'] : null;
    final whatsapp = user != null ? (user['whatsapp_number'] ?? user['phone_number']) : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A22), // Match the dark theme instead of white
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.phone, size: 20),
                label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  foregroundColor: Colors.deepPurpleAccent,
                  side: const BorderSide(color: Colors.deepPurpleAccent, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: phone != null ? () => _launchPhone(phone) : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final currentUser = ref.read(supabaseClientProvider).auth.currentUser;
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fadlan marka hore Login garee si aad u sheekaysato.')));
                    return;
                  }

                  try {
                    final chatId = await ref.read(chatNotifierProvider.notifier)
                        .createOrGetChat(widget.propertyId, data['owner_id']);
                    
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(chatId: chatId, title: widget.title),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                label: const Text('WA', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: whatsapp != null ? () => _launchWhatsApp(whatsapp, _propertyDetails!['title']) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
