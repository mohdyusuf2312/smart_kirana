import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_kirana/models/category_model.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/screens/admin/category_form_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/admin/admin_drawer.dart';

class CategoryManagementScreen extends StatefulWidget {
  static const String routeName = '/admin-categories';

  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

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
              const Text(
                'Unauthorized Access',
                style: AppTextStyles.heading1,
              ),
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
      appBar: AppBar(
        title: const Text('Category Management'),
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildCategoryList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CategoryFormScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(AppPadding.medium),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search categories...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildCategoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No categories found'),
          );
        }
        
        // Filter categories based on search query
        var filteredDocs = snapshot.data!.docs;
        
        if (_searchQuery.isNotEmpty) {
          filteredDocs = filteredDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] as String? ?? '';
            return name.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(AppPadding.medium),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final category = CategoryModel.fromMap(data, doc.id);
            
            return Card(
              margin: const EdgeInsets.only(bottom: AppPadding.medium),
              child: ListTile(
                leading: category.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppBorderRadius.small),
                        child: Image.network(
                          category.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.category),
                      ),
                title: Text(
                  category.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryFormScreen(
                              categoryId: category.id,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      onPressed: () {
                        _showDeleteConfirmation(category);
                      },
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryFormScreen(
                        categoryId: category.id,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This will affect all products in this category.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                // Check if there are products using this category
                final productsSnapshot = await _firestore
                    .collection('products')
                    .where('categoryId', isEqualTo: category.id)
                    .get();
                
                if (productsSnapshot.docs.isNotEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cannot delete category with associated products. Remove or reassign products first.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                  return;
                }
                
                // Delete the category
                await _firestore.collection('categories').doc(category.id).delete();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete category: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
