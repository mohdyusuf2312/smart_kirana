import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/models/recommendation_model.dart';
import 'package:smart_kirana/providers/product_provider.dart';
import 'package:smart_kirana/providers/recommendation_provider.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/admin/admin_drawer.dart';

class RecommendationManagementScreen extends StatefulWidget {
  static const String routeName = '/admin/recommendations';

  const RecommendationManagementScreen({super.key});

  @override
  State<RecommendationManagementScreen> createState() =>
      _RecommendationManagementScreenState();
}

class _RecommendationManagementScreenState
    extends State<RecommendationManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen for tab changes
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update floating action button
    });

    // Load data after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final recommendationProvider = Provider.of<RecommendationProvider>(
        context,
        listen: false,
      );

      // Load product data first to ensure products are available
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      await productProvider.loadProducts();

      // Load data with error handling
      await recommendationProvider.loadAllUserRecommendations();
      await recommendationProvider.loadGlobalRecommendations();

      debugPrint('Recommendation data loaded successfully');
    } catch (e) {
      debugPrint('Error loading recommendation data: $e');
      // Show error message if widget is still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recommendations: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendation Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'User Recommendations'),
            Tab(text: 'Global Recommendations'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildUserRecommendationsTab(),
                  _buildGlobalRecommendationsTab(),
                ],
              ),
      floatingActionButton:
          _tabController.index == 1
              ? FloatingActionButton(
                onPressed: () => _showAddProductDialog(isGlobal: true),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _buildUserRecommendationsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search users...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          // User recommendations list
          Expanded(child: _buildUserRecommendationsList()),
        ],
      ),
    );
  }

  Widget _buildUserRecommendationsList() {
    final recommendationProvider = Provider.of<RecommendationProvider>(context);
    final allUsers = recommendationProvider.allUserRecommendations;

    // Enhanced debug print to see what users are available
    debugPrint('All users count: ${allUsers.length}');
    for (var user in allUsers) {
      debugPrint(
        'User: ${user.userName}, ID: ${user.userId}, Products: ${user.products.length}, isGlobal: ${user.isGlobal}',
      );
      // Print product details for debugging
      if (user.products.isNotEmpty) {
        debugPrint('First product details for ${user.userName}:');
        final firstProduct = user.products.first;
        debugPrint('  ProductID: ${firstProduct.productId}');
        debugPrint('  ProductName: ${firstProduct.productName}');
        debugPrint('  ImageURL: ${firstProduct.imageUrl}');
        debugPrint('  Price: ${firstProduct.price}');
      }
    }

    // Filter users based on search query and exclude global recommendations
    final filteredUsers =
        allUsers
            .where(
              (user) =>
                  // Filter by search query
                  user.userName.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) &&
                  // Exclude global recommendations from user list
                  !user.isGlobal,
            )
            .toList();

    if (recommendationProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (recommendationProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${recommendationProvider.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (allUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No user recommendations found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Create a test user recommendation if none exist
                final recommendationProvider =
                    Provider.of<RecommendationProvider>(context, listen: false);

                // Get a product to add
                final productProvider = Provider.of<ProductProvider>(
                  context,
                  listen: false,
                );

                if (productProvider.products.isNotEmpty) {
                  final testProduct = productProvider.products.first;
                  await recommendationProvider.addProductToRecommendations(
                    'test_user_id',
                    'Test User',
                    testProduct,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Created test user recommendation'),
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No products available to create test recommendation',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Create Test User'),
            ),
          ],
        ),
      );
    }

    if (filteredUsers.isEmpty) {
      return const Center(child: Text('No users match your search'));
    }

    // Display the list of users with recommendations
    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ExpansionTile(
            title: Text(
              user.userName.isEmpty ? 'User ${index + 1}' : user.userName,
            ),
            subtitle: Text('${user.products.length} recommended products'),
            children: [
              SizedBox(
                height: 300,
                child:
                    user.products.isEmpty
                        ? const Center(child: Text('No recommendations yet'))
                        : ListView.builder(
                          itemCount: user.products.length,
                          itemBuilder: (context, productIndex) {
                            final product = user.products[productIndex];
                            return ListTile(
                              leading: SizedBox(
                                width: 50,
                                height: 50,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child:
                                      product.imageUrl.isNotEmpty
                                          ? Image.network(
                                            product.imageUrl,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              debugPrint(
                                                'Error loading image: $error',
                                              );
                                              return Container(
                                                width: 50,
                                                height: 50,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  size: 24,
                                                ),
                                              );
                                            },
                                          )
                                          : Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              size: 24,
                                            ),
                                          ),
                                ),
                              ),
                              title: Text(product.productName),
                              subtitle: Text(
                                'Price: ₹${product.price.toStringAsFixed(2)}${product.frequency > 1 ? ' • Ordered ${product.frequency} times' : ''}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.error,
                                ),
                                onPressed:
                                    () => _removeProductFromRecommendations(
                                      user.userId,
                                      product.productId,
                                    ),
                              ),
                            );
                          },
                        ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Generate Recommendations'),
                        onPressed:
                            () => _generateRecommendations(
                              user.userId,
                              user.userName.isEmpty
                                  ? 'User ${index + 1}'
                                  : user.userName,
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Product'),
                        onPressed:
                            () => _showAddProductDialog(
                              userId: user.userId,
                              userName:
                                  user.userName.isEmpty
                                      ? 'User ${index + 1}'
                                      : user.userName,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper methods for button functionality
  Future<void> _removeProductFromRecommendations(
    String userId,
    String productId,
  ) async {
    if (!mounted) return;

    // Don't set loading state for the whole screen
    // This prevents the screen from refreshing

    try {
      final recommendationProvider = Provider.of<RecommendationProvider>(
        context,
        listen: false,
      );

      // First update the UI directly to make it responsive
      // This will immediately remove the product from the UI without waiting for the database
      final allUsers = List<RecommendationModel>.from(
        recommendationProvider.allUserRecommendations,
      );

      // Find the user in the list
      final userIndex = allUsers.indexWhere((user) => user.userId == userId);
      if (userIndex >= 0) {
        // Create a new user object with the product removed
        final updatedUser = allUsers[userIndex].copyWith(
          products:
              allUsers[userIndex].products
                  .where((product) => product.productId != productId)
                  .toList(),
        );

        // Update the list
        allUsers[userIndex] = updatedUser;

        // Force a rebuild of just this widget
        setState(() {
          // The state update is just to trigger a rebuild
          // The actual data is updated in the provider
        });
      }

      // Then update the database in the background
      await recommendationProvider.removeProductFromRecommendations(
        userId,
        productId,
        updateUIOnly: true, // Don't reload data from database
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product removed from recommendations')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to remove product: $e')));
      }
    }
  }

  Future<void> _generateRecommendations(String userId, String userName) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final recommendationProvider = Provider.of<RecommendationProvider>(
        context,
        listen: false,
      );

      await recommendationProvider.generateRecommendationsForUser(
        userId,
        userName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recommendations generated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate recommendations: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddProductDialog({
    String? userId,
    String? userName,
    bool isGlobal = false,
  }) {
    if (!mounted) return;

    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final products = productProvider.products;

    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products available to add')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        List<ProductModel> filteredProducts = products;

        return StatefulBuilder(
          builder: (context, setState) {
            filteredProducts =
                products
                    .where(
                      (product) => product.name.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

            return AlertDialog(
              title: Text(
                isGlobal
                    ? 'Add Global Recommendation'
                    : 'Add Product to ${userName ?? 'User'} Recommendations',
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
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
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child:
                          filteredProducts.isEmpty
                              ? const Center(child: Text('No products found'))
                              : ListView.builder(
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
                                  return ListTile(
                                    leading: SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child:
                                            product.imageUrl.isNotEmpty
                                                ? Image.network(
                                                  product.imageUrl,
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    debugPrint(
                                                      'Error loading product image in dialog: $error',
                                                    );
                                                    return Container(
                                                      width: 40,
                                                      height: 40,
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        size: 20,
                                                      ),
                                                    );
                                                  },
                                                )
                                                : Container(
                                                  width: 40,
                                                  height: 40,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.image_not_supported,
                                                    size: 20,
                                                  ),
                                                ),
                                      ),
                                    ),
                                    title: Text(product.name),
                                    subtitle: Text(
                                      '₹${product.price.toStringAsFixed(2)}',
                                    ),
                                    onTap: () {
                                      Navigator.pop(context, product);
                                    },
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    ).then((selectedProduct) {
      if (selectedProduct != null && mounted) {
        _addProductToRecommendations(
          userId,
          userName,
          selectedProduct as ProductModel,
          isGlobal,
        );
      }
    });
  }

  Future<void> _addProductToRecommendations(
    String? userId,
    String? userName,
    ProductModel product,
    bool isGlobal,
  ) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final recommendationProvider = Provider.of<RecommendationProvider>(
        context,
        listen: false,
      );

      if (isGlobal) {
        await recommendationProvider.addProductToGlobalRecommendations(product);
      } else if (userId != null && userName != null) {
        await recommendationProvider.addProductToRecommendations(
          userId,
          userName,
          product,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added to recommendations')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add product: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildGlobalRecommendationsTab() {
    final recommendationProvider = Provider.of<RecommendationProvider>(context);
    final globalRecommendations = recommendationProvider.globalRecommendations;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Global Recommendations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                globalRecommendations == null ||
                        globalRecommendations.products.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shopping_basket_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text('No global recommendations yet'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed:
                                () => _showAddProductDialog(isGlobal: true),
                            child: const Text('Add Global Recommendation'),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: globalRecommendations.products.length,
                      itemBuilder: (context, index) {
                        final product = globalRecommendations.products[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            leading: SizedBox(
                              width: 50,
                              height: 50,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child:
                                    product.imageUrl.isNotEmpty
                                        ? Image.network(
                                          product.imageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            debugPrint(
                                              'Error loading global image: $error',
                                            );
                                            return Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                size: 24,
                                              ),
                                            );
                                          },
                                        )
                                        : Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            size: 24,
                                          ),
                                        ),
                              ),
                            ),
                            title: Text(product.productName),
                            subtitle: Text(
                              'Price: ₹${product.price.toStringAsFixed(2)}${product.frequency > 1 ? ' • Ordered ${product.frequency} times' : ''}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: AppColors.error,
                              ),
                              onPressed:
                                  () => _removeProductFromRecommendations(
                                    globalRecommendations.userId,
                                    product.productId,
                                  ),
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
}
