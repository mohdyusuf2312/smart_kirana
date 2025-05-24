import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/screens/admin/product_form_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/admin/admin_drawer.dart';

class LowStockScreen extends StatefulWidget {
  static const String routeName = '/admin-low-stock';

  const LowStockScreen({super.key});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = false;
  List<String> _categories = ['All'];

  // Define low stock threshold
  static const int _lowStockThreshold = 10;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categoriesSnapshot =
          await _firestore.collection('categories').get();
      final categories = ['All'];

      for (var doc in categoriesSnapshot.docs) {
        final data = doc.data();
        categories.add(data['name'] as String? ?? '');
      }

      setState(() {
        _categories = categories;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
      appBar: AppBar(title: const Text('Low Stock Products')),
      drawer: const AdminDrawer(),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildSearchAndFilter(),
                  Expanded(child: _buildLowStockProductList()),
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
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: AppPadding.small),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Filter by Category',
              border: OutlineInputBorder(),
            ),
            value: _selectedCategory,
            items:
                _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products found'));
        }

        // Debug: Print all products and their stock levels
        debugPrint('Total products: ${snapshot.data!.docs.length}');

        // Create a list to store products with their stock levels for debugging
        List<Map<String, dynamic>> productsWithStock = [];

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name'] as String? ?? 'Unknown';

          // Handle different stock types
          var stockValue = data['stock'];
          int stock = 0;

          if (stockValue is int) {
            stock = stockValue;
          } else if (stockValue is double) {
            stock = stockValue.toInt();
          } else if (stockValue is String) {
            stock = int.tryParse(stockValue) ?? 0;
          } else if (stockValue is num) {
            stock = stockValue.toInt();
          }

          productsWithStock.add({
            'id': doc.id,
            'name': name,
            'stock': stock,
            'stockType': stockValue.runtimeType.toString(),
          });

          debugPrint(
            'Product: $name, Stock: $stock, Type: ${stockValue.runtimeType}',
          );
        }

        // Sort by stock for debugging
        productsWithStock.sort(
          (a, b) => (a['stock'] as int).compareTo(b['stock'] as int),
        );
        debugPrint(
          'Products sorted by stock: ${productsWithStock.map((p) => "${p['name']}: ${p['stock']}").join(', ')}',
        );

        // Filter products based on low stock, search query and category
        var filteredDocs =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              var stockValue = data['stock'];
              int stock = 0;

              // Handle different stock types
              if (stockValue is int) {
                stock = stockValue;
              } else if (stockValue is double) {
                stock = stockValue.toInt();
              } else if (stockValue is String) {
                stock = int.tryParse(stockValue) ?? 0;
              } else if (stockValue is num) {
                stock = stockValue.toInt();
              }

              // Check if stock is low (including zero)
              return stock < _lowStockThreshold;
            }).toList();

        if (_searchQuery.isNotEmpty) {
          filteredDocs =
              filteredDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name'] as String? ?? '';
                return name.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();
        }

        if (_selectedCategory != 'All') {
          filteredDocs =
              filteredDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final categoryName = data['categoryName'] as String? ?? '';
                return categoryName == _selectedCategory;
              }).toList();
        }

        // Debug: Print filtered products
        debugPrint('Filtered products count: ${filteredDocs.length}');
        for (var doc in filteredDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name'] as String? ?? 'Unknown';
          var stockValue = data['stock'];
          int stock = 0;

          // Handle different stock types
          if (stockValue is int) {
            stock = stockValue;
          } else if (stockValue is double) {
            stock = stockValue.toInt();
          } else if (stockValue is String) {
            stock = int.tryParse(stockValue) ?? 0;
          } else if (stockValue is num) {
            stock = stockValue.toInt();
          }

          debugPrint(
            'Filtered Product: $name, Stock: $stock, Type: ${stockValue.runtimeType}',
          );
        }

        if (filteredDocs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No low stock products found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'All products have sufficient stock levels',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Sort by stock level (ascending)
        filteredDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          var aStockValue = aData['stock'];
          int aStock = 0;
          if (aStockValue is int) {
            aStock = aStockValue;
          } else if (aStockValue is double) {
            aStock = aStockValue.toInt();
          } else if (aStockValue is String) {
            aStock = int.tryParse(aStockValue) ?? 0;
          } else if (aStockValue is num) {
            aStock = aStockValue.toInt();
          }

          var bStockValue = bData['stock'];
          int bStock = 0;
          if (bStockValue is int) {
            bStock = bStockValue;
          } else if (bStockValue is double) {
            bStock = bStockValue.toInt();
          } else if (bStockValue is String) {
            bStock = int.tryParse(bStockValue) ?? 0;
          } else if (bStockValue is num) {
            bStock = bStockValue.toInt();
          }

          return aStock.compareTo(bStock);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(AppPadding.medium),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;

            // Ensure stock is properly converted to int before creating the product model
            var stockValue = data['stock'];
            int stock = 0;

            if (stockValue is int) {
              stock = stockValue;
            } else if (stockValue is double) {
              stock = stockValue.toInt();
            } else if (stockValue is String) {
              stock = int.tryParse(stockValue) ?? 0;
            } else if (stockValue is num) {
              stock = stockValue.toInt();
            }

            // Create a copy of data with corrected stock value
            final Map<String, dynamic> correctedData =
                Map<String, dynamic>.from(data);
            correctedData['stock'] = stock;

            final product = ProductModel.fromMap(correctedData, doc.id);

            return Card(
              margin: const EdgeInsets.only(bottom: AppPadding.medium),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(product.imageUrl),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                  ),
                ),
                title: Text(
                  product.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category: ${product.categoryName}'),
                    Row(
                      children: [
                        Text('Stock: ', style: AppTextStyles.bodyMedium),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withAlpha(
                              51,
                            ), // ~0.2 opacity
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.small,
                            ),
                          ),
                          child: Text(
                            '${product.stock}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text('Price: ₹${product.price.toStringAsFixed(2)}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                ProductFormScreen(productId: product.id),
                      ),
                    );
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ProductFormScreen(productId: product.id),
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
}
