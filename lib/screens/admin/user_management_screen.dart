import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/user_model.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/admin/admin_drawer.dart';

class UserManagementScreen extends StatefulWidget {
  static const String routeName = '/admin-users';

  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _selectedRole = 'All';
  String? _selectedUserId;
  final List<String> _roleOptions = ['All', 'CUSTOMER', 'ADMIN'];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Check if user is admin
    if (authProvider.user?.role != 'ADMIN') {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Unauthorized Access', style: AppTextStyles.heading1),
              const SizedBox(height: AppPadding.medium),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child:
                _selectedUserId != null
                    ? _buildUserDetails()
                    : _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(AppPadding.medium),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: AppPadding.medium),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _roleOptions.length,
              itemBuilder: (context, index) {
                final role = _roleOptions[index];
                final isSelected = role == _selectedRole;

                return Padding(
                  padding: const EdgeInsets.only(right: AppPadding.small),
                  child: ChoiceChip(
                    label: Text(role),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedRole = role;
                        });
                      }
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color:
                          isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found'));
        }

        // Filter users based on search query and role
        var filteredDocs = snapshot.data!.docs;

        if (_searchQuery.isNotEmpty) {
          filteredDocs =
              filteredDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name'] as String? ?? '';
                final email = data['email'] as String? ?? '';

                return name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    email.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();
        }

        if (_selectedRole != 'All') {
          filteredDocs =
              filteredDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final role = data['role'] as String? ?? 'CUSTOMER';

                return role == _selectedRole;
              }).toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppPadding.medium),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final user = UserModel.fromMap(data, doc.id);

            return Card(
              margin: const EdgeInsets.only(bottom: AppPadding.medium),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  user.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.email),
                    Text('Phone: ${user.phone}'),
                    Row(children: [Text('Role: '), _buildRoleChip(user.role)]),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () {
                    setState(() {
                      _selectedUserId = user.id;
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    _selectedUserId = user.id;
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserDetails() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(_selectedUserId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('User not found'),
                const SizedBox(height: AppPadding.medium),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedUserId = null;
                    });
                  },
                  child: const Text('Back to Users'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final user = UserModel.fromMap(data, snapshot.data!.id);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppPadding.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedUserId = null;
                      });
                    },
                  ),
                  const Text('User Details', style: AppTextStyles.heading2),
                ],
              ),
              const SizedBox(height: AppPadding.medium),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppPadding.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppPadding.medium),
                      _buildUserInfoRow('Name', user.name),
                      _buildUserInfoRow('Email', user.email),
                      _buildUserInfoRow('Phone', user.phone),
                      _buildUserInfoRow(
                        'Verified',
                        user.isVerified ? 'Yes' : 'No',
                      ),
                      _buildUserInfoRow(
                        'Created At',
                        DateFormat('MMM d, yyyy').format(user.createdAt),
                      ),
                      _buildUserInfoRow(
                        'Last Login',
                        DateFormat(
                          'MMM d, yyyy hh:mm a',
                        ).format(user.lastLogin),
                      ),
                      const SizedBox(height: AppPadding.medium),
                      _buildUserInfoRow('Role', user.role),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppPadding.medium),
              if (user.addresses.isNotEmpty) ...[
                const Text('Addresses', style: AppTextStyles.heading3),
                const SizedBox(height: AppPadding.small),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: user.addresses.length,
                  itemBuilder: (context, index) {
                    final address = user.addresses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppPadding.small),
                      child: ListTile(
                        title: Text(
                          address.addressLine,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${address.city}, ${address.state}, ${address.pincode}',
                        ),
                        trailing:
                            address.isDefault
                                ? const Chip(
                                  label: Text(
                                    'Default',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: AppColors.primary,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                )
                                : null,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyLarge)),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    return Chip(
      label: Text(
        role,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor:
          role == 'ADMIN' ? AppColors.secondary : AppColors.primary,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
