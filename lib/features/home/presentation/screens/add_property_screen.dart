import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../providers/categories_provider.dart';

class AddPropertyScreen extends ConsumerStatefulWidget {
  const AddPropertyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _sqmController = TextEditingController();
  
  String _propertyType = 'Apartment';
  // Note: _types will be populated from categoriesProvider in build
  
  String _selectedCity = 'Muqdisho';
  final List<String> _cities = ['Muqdisho', 'Hargeysa', 'Borama', 'Garowe', 'Kismaayo'];
  
  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _sqmController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one image')));
      return;
    }

    setState(() => _isLoading = true);
    final supabase = ref.read(supabaseClientProvider);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Insert property to get ID
      final propertyData = {
        'owner_id': user.id,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'price_per_month': double.parse(_priceController.text.trim()),
        'address': _addressController.text.trim(),
        'city': _selectedCity,
        'property_type': _propertyType,
        'bedrooms': int.parse(_bedroomsController.text.trim()),
        'bathrooms': int.parse(_bathroomsController.text.trim()),
        'square_meters': _sqmController.text.trim().isNotEmpty ? double.parse(_sqmController.text.trim()) : null,
      };

      final propertyResponse = await supabase.from('properties').insert(propertyData).select().single();
      final propertyId = propertyResponse['id'];

      // 2. Upload images and save to property_media
      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];
        final ext = image.name.split('.').last;
        final fileName = '\${DateTime.now().millisecondsSinceEpoch}_\$i.\$ext';
        final filePath = 'properties/\$propertyId/\$fileName';

        await supabase.storage.from('property_media').upload(filePath, File(image.path));
        final mediaUrl = supabase.storage.from('property_media').getPublicUrl(filePath);

        // 3. Save to property_media table
        await supabase.from('property_media').insert({
          'property_id': propertyId,
          'media_url': mediaUrl,
          'is_thumbnail': i == 0,
        });

        // 4. If it's the first image, update the main property thumbnail_url for quick access
        if (i == 0) {
          await supabase.from('properties').update({
            'thumbnail_url': mediaUrl,
          }).eq('id', propertyId);
        }
      }

      // 5. Notify Super Admins
      try {
        final superAdmins = await supabase.from('users').select('id').eq('role', 'super_admin');
        for (final admin in superAdmins) {
          await supabase.from('notifications').insert({
            'user_id': admin['id'],
            'title': 'Guri Cusub (Approval Needed)',
            'message': 'Guri cusub oo ciwaankiisu yahay "${_titleController.text}" ayaa la soo galiyey. Fadlan hubi oo ansixi.',
            'type': 'approval_request',
            'related_id': propertyId,
          });
        }
      } catch (e) {
        // Silently fail notification if it errors
        print('Notification error: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Property added successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Property')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Property Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 3,
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(labelText: 'Price / Month (\$)', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ref.watch(categoriesProvider).when(
                          data: (categories) {
                            if (!categories.contains(_propertyType)) {
                              _propertyType = categories.isNotEmpty ? categories.first : 'Apartment';
                            }
                            return DropdownButtonFormField<String>(
                              value: _propertyType,
                              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                              items: categories.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (val) => setState(() => _propertyType = val!),
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (e, s) => Text('Error: $e'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCity,
                          decoration: const InputDecoration(labelText: 'Magaalada (City)', border: OutlineInputBorder()),
                          items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) => setState(() => _selectedCity = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bedroomsController,
                          decoration: const InputDecoration(labelText: 'Bedrooms', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _bathroomsController,
                          decoration: const InputDecoration(labelText: 'Bathrooms', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sqmController,
                          decoration: const InputDecoration(labelText: 'Sqm (opt)', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._selectedImages.map((img) => Stack(
                            children: [
                              Image.file(File(img.path), width: 100, height: 100, fit: BoxFit.cover),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => setState(() => _selectedImages.remove(img)),
                                ),
                              ),
                            ],
                          )),
                      InkWell(
                        onTap: _pickImages,
                        child: Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.add_a_photo, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitProperty,
                      child: const Text('Save Property', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
