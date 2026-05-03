import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/admin_client_provider.dart';
import '../providers/categories_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _userRole = 'user';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase.from('users').select('role').eq('id', user.id).single();
      setState(() {
        _userRole = response['role'];
        _isLoading = false;
      });
    }
  }

  void _confirmResetDatabase() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Database?'),
        content: const Text(
          'This will DELETE ALL properties, categories, messages, and other users. '
          'ONLY your super admin account will be kept. This action is IRREVERSIBLE.',
          style: TextStyle(color: Colors.redAccent),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetDatabase();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('RESET EVERYTHING'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetDatabase() async {
    setState(() => _isLoading = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      final adminClient = ref.read(adminSupabaseClientProvider);
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) return;

      // 1. Get all users except current super admin
      final List<dynamic> users = await supabase
          .from('users')
          .select('id')
          .neq('id', currentUserId);

      // 2. Delete all other users from auth (will cascade to public.users and everything else)
      for (final u in users) {
        await adminClient.auth.admin.deleteUser(u['id']);
      }

      // 3. Clear other tables that might not cascade or need specific clearing
      await supabase.from('categories').delete().neq('id', '00000000-0000-0000-0000-000000000000'); // Delete all categories
      await supabase.from('properties').delete().neq('id', '00000000-0000-0000-0000-000000000000'); // Delete all properties (if any left)
      await supabase.from('chat_rooms').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await supabase.from('messages').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await supabase.from('favorites').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await supabase.from('property_analytics').delete().neq('id', '00000000-0000-0000-0000-000000000000');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database reset successfully! All data cleared.')),
        );
        // Refresh the view
        _fetchUserRole();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error resetting database: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userRole != 'admin' && _userRole != 'super_admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(child: Text('You do not have permission to view this page.')),
      );
    }

    return DefaultTabController(
      length: _userRole == 'super_admin' ? 4 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_userRole == 'super_admin' ? 'Super Admin Dashboard' : 'Admin Dashboard'),
          actions: [
            if (_userRole == 'super_admin')
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                onPressed: _confirmResetDatabase,
                tooltip: 'Reset Database (Delete everything except you)',
              ),
          ],
          bottom: TabBar(
            tabs: [
              const Tab(icon: Icon(Icons.home), text: 'Properties'),
              if (_userRole == 'super_admin') ...[
                const Tab(icon: Icon(Icons.people), text: 'Users'),
                const Tab(icon: Icon(Icons.category), text: 'Categories'),
                const Tab(icon: Icon(Icons.trending_up), text: 'Promotions'),
              ],
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PropertiesAdminTab(isSuperAdmin: _userRole == 'super_admin'),
            if (_userRole == 'super_admin') ...[
              _UsersAdminTab(),
              _CategoriesAdminTab(),
              _PromotionsAdminTab(),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoriesAdminTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final controller = TextEditingController();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Add Category'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Category Name'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      ref.read(categoriesNotifierProvider.notifier).addCategory(controller.text.trim());
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
      body: categoriesAsync.when(
        data: (categories) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return Card(
              child: ListTile(
                title: Text(cat),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => ref.read(categoriesNotifierProvider.notifier).deleteCategory(cat),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _PropertiesAdminTab extends ConsumerStatefulWidget {
  final bool isSuperAdmin;
  const _PropertiesAdminTab({required this.isSuperAdmin});

  @override
  ConsumerState<_PropertiesAdminTab> createState() => _PropertiesAdminTabState();
}

class _PropertiesAdminTabState extends ConsumerState<_PropertiesAdminTab> {
  late Future<List<dynamic>> _propertiesFuture;

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  void _fetchProperties() {
    setState(() {
      _propertiesFuture = ref.read(supabaseClientProvider)
          .from('properties')
          .select('id, title, is_approved, is_promoted, price_per_month')
          .order('created_at', ascending: false);
    });
  }

  Future<void> _toggleApproval(String id, bool currentStatus) async {
    final supabase = ref.read(supabaseClientProvider);
    final newStatus = !currentStatus;
    
    await supabase
        .from('properties')
        .update({'is_approved': newStatus})
        .eq('id', id);
    
    // Notify the owner if approved
    if (newStatus) {
      try {
        final property = await supabase.from('properties').select('owner_id, title').eq('id', id).single();
        await supabase.from('notifications').insert({
          'user_id': property['owner_id'],
          'title': 'Gurigaaga waa la ansixiyey!',
          'message': 'Gurigii aad soo gelisay ee "${property['title']}" waa la ansixiyey, hadda dadka oo dhan ayaa arki kara.',
          'type': 'property_approved',
          'related_id': id,
        });
      } catch (e) {
        print('Notification error: $e');
      }
    }
    
    _fetchProperties();
  }

  Future<void> _deleteProperty(String id) async {
    await ref.read(supabaseClientProvider).from('properties').delete().eq('id', id);
    _fetchProperties();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _propertiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final properties = snapshot.data ?? [];
        if (properties.isEmpty) return const Center(child: Text('No properties found.'));

        return ListView.builder(
          itemCount: properties.length,
          itemBuilder: (context, index) {
            final p = properties[index];
            final isApproved = p['is_approved'] ?? false;
            final isPromoted = p['is_promoted'] ?? false;
            
            return ListTile(
              title: Text(p['title']),
              subtitle: Text('\$${p['price_per_month']} / mo'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Promote Toggle
                  if (widget.isSuperAdmin)
                    IconButton(
                      icon: Icon(
                        isPromoted ? Icons.star : Icons.star_border,
                        color: isPromoted ? Colors.amber : Colors.grey,
                      ),
                      onPressed: () => _togglePromote(p['id'], isPromoted),
                      tooltip: 'Promote to Slider',
                    ),
                  const SizedBox(width: 8),
                  // Approval Toggle
                  Switch(
                    value: isApproved,
                    onChanged: (val) => _toggleApproval(p['id'], isApproved),
                    activeColor: Colors.green,
                  ),
                  if (widget.isSuperAdmin)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteProperty(p['id']),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _togglePromote(String id, bool currentStatus) async {
    try {
      await ref.read(supabaseClientProvider)
          .from('properties')
          .update({'is_promoted': !currentStatus})
          .eq('id', id);
      _fetchProperties();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _UsersAdminTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_UsersAdminTab> createState() => _UsersAdminTabState();
}

class _UsersAdminTabState extends ConsumerState<_UsersAdminTab> {
  late Future<List<dynamic>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() {
    setState(() {
      _usersFuture = ref.read(supabaseClientProvider)
          .from('users')
          .select('id, first_name, role, is_approved, email, registered_by')
          .order('created_at', ascending: false);
    });
  }

  Future<void> _toggleUserApproval(String id, bool currentStatus) async {
    await ref.read(supabaseClientProvider)
        .from('users')
        .update({'is_approved': !currentStatus})
        .eq('id', id);
    _fetchUsers();
  }

  Future<void> _changeRole(String id, String currentRole) async {
    final newRole = currentRole == 'user' ? 'admin' : 'user';
    await ref.read(supabaseClientProvider)
        .from('users')
        .update({'role': newRole})
        .eq('id', id);
    _fetchUsers();
  }

  Future<void> _resetPassword(String id, String firstName) async {
    final passController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Password for $firstName'),
        content: TextField(
          controller: passController,
          decoration: const InputDecoration(labelText: 'New Password (min 6 chars)'),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (passController.text.length < 6) return;
              Navigator.pop(ctx);
              try {
                final adminClient = ref.read(adminSupabaseClientProvider);
                await adminClient.auth.admin.updateUserById(
                  id,
                  attributes: AdminUserAttributes(password: passController.text),
                );
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _createAdmin() async {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passController, decoration: const InputDecoration(labelText: 'Password (min 6 chars)'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isEmpty || passController.text.length < 6) return;
              Navigator.pop(ctx);
              try {
                final adminClient = ref.read(adminSupabaseClientProvider);
                // 1. Create auth user
                final res = await adminClient.auth.admin.createUser(
                  AdminUserAttributes(
                    email: emailController.text.trim(),
                    password: passController.text,
                    emailConfirm: true,
                  ),
                );
                
                if (res.user != null) {
                  // Wait a bit for the DB trigger to create the public.users row
                  await Future.delayed(const Duration(seconds: 1));
                  
                  // 2. Update role to admin and set first name and approve
                  final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;
                  await ref.read(supabaseClientProvider).from('users').update({
                    'role': 'admin',
                    'first_name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'is_approved': true,
                    'registered_by': currentUserId,
                  }).eq('id', res.user!.id);

                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin created successfully!')));
                  _fetchUsers();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAdmin,
        icon: const Icon(Icons.person_add),
        label: const Text('New Admin'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) return const Center(child: Text('No users found.'));

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final u = users[index];
              if (u['role'] == 'super_admin') return const SizedBox.shrink(); // Don't edit super admins
              
              final name = u['first_name'] ?? 'Unknown User';
              final isApproved = u['is_approved'] ?? false;
              final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;
              final registeredByMe = u['registered_by'] == currentUserId;

              return ListTile(
                title: Row(
                  children: [
                    Text(name),
                    if (registeredByMe)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5)),
                        ),
                        child: const Text('Registered by me', style: TextStyle(fontSize: 10, color: Colors.deepPurpleAccent)),
                      ),
                  ],
                ),
                subtitle: Text('Role: ${u['role']} | Email: ${u['email'] ?? 'N/A'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Approved', style: TextStyle(fontSize: 10)),
                        Switch(
                          value: isApproved,
                          onChanged: (val) => _toggleUserApproval(u['id'], isApproved),
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.vpn_key, color: Colors.amber),
                      tooltip: 'Reset Password',
                      onPressed: () => _resetPassword(u['id'], name),
                    ),
                    ElevatedButton(
                      onPressed: () => _changeRole(u['id'], u['role']),
                      child: Text(u['role'] == 'user' ? 'Make Admin' : 'Remove Admin'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class _PromotionsAdminTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PromotionsAdminTab> createState() => _PromotionsAdminTabState();
}

class _PromotionsAdminTabState extends ConsumerState<_PromotionsAdminTab> {
  late Future<List<dynamic>> _promotionsFuture;

  @override
  void initState() {
    super.initState();
    _fetchPromotions();
  }

  void _fetchPromotions() {
    setState(() {
      _promotionsFuture = ref.read(supabaseClientProvider)
          .from('promotions')
          .select('*, properties(title)')
          .order('created_at', ascending: false);
    });
  }

  Future<void> _updateStatus(String id, String status) async {
    final supabase = ref.read(supabaseClientProvider);
    final bool isActive = status == 'approved';
    
    await supabase
        .from('promotions')
        .update({
          'status': status,
          'is_active': isActive,
        })
        .eq('id', id);

    // Notify the owner
    if (status == 'approved') {
      try {
        final promo = await supabase
            .from('promotions')
            .select('property_id, properties(owner_id, title)')
            .eq('id', id)
            .single();
            
        await supabase.from('notifications').insert({
          'user_id': promo['properties']['owner_id'],
          'title': 'Promotion-kaagii waa la ansixiyey!',
          'message': 'Gurigaaga "${promo['properties']['title']}" hadda wuxuu ka soo muuqanayaa Slider-ka sare ee app-ka.',
          'type': 'promotion_approved',
          'related_id': promo['property_id'],
        });
      } catch (e) {
        print('Notification error: $e');
      }
    }
    
    _fetchPromotions();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _promotionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final promos = snapshot.data ?? [];
        if (promos.isEmpty) return const Center(child: Text('No promotion requests found.'));

        return ListView.builder(
          itemCount: promos.length,
          itemBuilder: (context, index) {
            final pr = promos[index];
            final propertyTitle = pr['properties']['title'] ?? 'Unknown Property';
            final status = pr['status'] ?? 'pending';
            final startDate = DateTime.parse(pr['start_date']);
            final endDate = DateTime.parse(pr['end_date']);
            final duration = endDate.difference(startDate).inDays;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(propertyTitle),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Duration: $duration days'),
                    Text('Status: ${status.toUpperCase()}', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: status == 'pending' ? Colors.orange : (status == 'approved' ? Colors.green : Colors.red)
                      )
                    ),
                  ],
                ),
                trailing: status == 'pending' 
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => _updateStatus(pr['id'], 'approved'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _updateStatus(pr['id'], 'rejected'),
                        ),
                      ],
                    )
                  : (status == 'approved' 
                      ? const Icon(Icons.verified, color: Colors.green)
                      : const Icon(Icons.error_outline, color: Colors.red)),
              ),
            );
          },
        );
      },
    );
  }
}
