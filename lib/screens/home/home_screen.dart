import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/product_model.dart';

import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/providers/cart_provider.dart';
import 'package:smart_kirana/providers/product_provider.dart';
import 'package:smart_kirana/providers/recommendation_provider.dart';

import 'package:smart_kirana/screens/home/cart_screen.dart';
import 'package:smart_kirana/screens/home/product_detail_screen.dart';
import 'package:smart_kirana/screens/home/product_list_screen.dart';
import 'package:smart_kirana/screens/home/profile_screen.dart';
import 'package:smart_kirana/services/location_service.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/product_filter_widget.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Navigation state
  int _currentIndex = 0;

  // Loading state
  bool _isLoading = true;
  String _errorMessage = '';

  // Location state
  final LocationService _locationService = LocationService();
  String _deliveryLocation = 'Detecting location...';
  String _deliveryTime = '15 minutes';

  // Filtering state
  ProductFilterOptions _filterOptions = ProductFilterOptions();

  // Search state
  bool _isSearchActive = false;
  String _searchQuery = '';
  List<ProductModel> _searchResults = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Key for refresh indicator
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    // Use post-frame callback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Initialize location service in background (non-blocking)
      _initializeLocation(); // Don't await this

      // Load products and categories
      if (mounted) {
        await _loadProductData();
      }

      // Load user recommendations if user is logged in
      if (mounted) {
        await _loadUserRecommendations();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error initializing screen: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserRecommendations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final recommendationProvider = Provider.of<RecommendationProvider>(
      context,
      listen: false,
    );

    try {
      // Load global recommendations for all users
      await recommendationProvider.loadGlobalRecommendations();

      // Also load user-specific recommendations if user is logged in
      if (authProvider.currentUser != null && authProvider.user != null) {
        // Pass both user ID and user name for recommendation refresh check
        await recommendationProvider.loadUserRecommendations(
          authProvider.currentUser!.uid,
          userName: authProvider.user!.name,
        );
      }
    } catch (e) {
      // debugPrint('Error loading recommendations: $e');
      // Don't set error message here to avoid blocking the whole screen
    }
  }

  Future<void> _initializeLocation() async {
    try {
      bool initialized = await _locationService.initialize();
      if (initialized && mounted) {
        final address = _locationService.currentAddress;

        setState(() {
          _deliveryLocation = address ?? 'Location not available';
          _deliveryTime = _locationService.getEstimatedDeliveryTime();
        });

        // Note: Not saving location to database as per user request
      } else {
        if (mounted) {
          setState(() {
            _deliveryLocation = 'Location not available';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deliveryLocation = 'Location not available';
        });
      }
    }
  }

  // Authentication is now handled by HomeWrapper

  Future<void> _loadProductData() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    try {
      // Load categories and products
      await productProvider.loadCategories();
      await productProvider.loadProducts();

      // Setup real-time listeners for product updates
      // Note: This is now handled in the ProductProvider constructor
      // productProvider.setupProductListeners();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load products: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _errorMessage = '';
    });

    try {
      // Refresh location
      await _initializeLocation();

      // Refresh product data
      await _loadProductData();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to refresh data: ${e.toString()}';
        });
      }
    }
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearchActive = false;
        _searchQuery = '';
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearchActive = true;
      _searchQuery = query.trim().toLowerCase();
      _isSearching = true;
    });

    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final allProducts = productProvider.products;

    // Filter products based on search query
    final results =
        allProducts.where((product) {
          final nameMatch = product.name.toLowerCase().contains(_searchQuery);
          final descriptionMatch = product.description.toLowerCase().contains(
            _searchQuery,
          );
          final categoryMatch = product.categoryName.toLowerCase().contains(
            _searchQuery,
          );
          return nameMatch || descriptionMatch || categoryMatch;
        }).toList();

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearchActive = false;
      _searchQuery = '';
      _searchResults = [];
      _isSearching = false;
    });
  }

  void _showFilterDialog() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder:
                (context, scrollController) => ProductFilterWidget(
                  initialFilters: _filterOptions,
                  categories: productProvider.categories,
                  onFiltersChanged: (filters) {
                    setState(() {
                      _filterOptions = filters;
                    });
                  },
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          _currentIndex == 0
              ? _buildHomeAppBar(context)
              : AppBar(
                title: _buildAppBarTitle(),
                actions: _buildAppBarActions(),
              ),
      body:
          _isLoading
              ? _buildLoadingView()
              : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    // Use IndexedStack for better performance and state preservation
    return IndexedStack(
      index: _currentIndex,
      sizing: StackFit.expand,
      children: [_buildHomeTab(), const CartScreen(), const ProfileScreen()],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
      ],
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_currentIndex != 0) return null;

    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        if (cartProvider.cartItems.isEmpty) {
          return const SizedBox.shrink();
        }

        // Calculate total items
        int totalItems = cartProvider.cartItems.fold(
          0,
          (sum, item) => sum + item.quantity,
        );

        return FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              _currentIndex = 1;
            });
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.shopping_cart),
          label: Text(
            '$totalItems | ₹${cartProvider.total.toStringAsFixed(2)}',
          ),
        );
      },
    );
  }

  Widget _buildLocationBanner() {
    bool isLocationAvailable =
        _deliveryLocation != 'Detecting location...' &&
        _deliveryLocation != 'Location not available';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Icon(
            isLocationAvailable ? Icons.location_on : Icons.location_searching,
            size: 16,
            color: isLocationAvailable ? AppColors.secondary : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLocationAvailable
                      ? 'Delivery to:'
                      : 'Detecting location...',
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isLocationAvailable
                            ? Colors.grey.shade600
                            : Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _deliveryLocation,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isLocationAvailable
                            ? Colors.black87
                            : Colors.orange.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isLocationAvailable) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 10, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _deliveryTime,
                    style: const TextStyle(fontSize: 9, color: Colors.white),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMergedRecommendationsSection() {
    final productProvider = Provider.of<ProductProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final recommendationProvider = Provider.of<RecommendationProvider>(context);

    List<ProductModel> mergedRecommendations = [];

    // Collect user-specific recommendations if user is logged in
    if (authProvider.currentUser != null &&
        recommendationProvider.userRecommendations != null &&
        recommendationProvider.userRecommendations!.products.isNotEmpty) {
      final userRecommendations =
          recommendationProvider.userRecommendations!.products;
      for (var recommendation in userRecommendations) {
        final product = productProvider.getProductById(
          recommendation.productId,
        );
        if (product != null) {
          mergedRecommendations.add(product);
        }
      }
    }

    // Collect global recommendations
    if (recommendationProvider.globalRecommendations != null &&
        recommendationProvider.globalRecommendations!.products.isNotEmpty) {
      final globalRecommendations =
          recommendationProvider.globalRecommendations!.products;
      for (var recommendation in globalRecommendations) {
        final product = productProvider.getProductById(
          recommendation.productId,
        );
        if (product != null && !mergedRecommendations.contains(product)) {
          mergedRecommendations.add(product);
        }
      }
    }

    // If no recommendations from either source, fall back to popular products
    if (mergedRecommendations.isEmpty) {
      mergedRecommendations =
          productProvider.getPopularProducts().take(8).toList();
    }

    // Apply filters to recommendations
    if (_filterOptions.hasActiveFilters) {
      mergedRecommendations =
          productProvider
              .filterProducts(
                categoryId: _filterOptions.categoryId,
                minPrice: _filterOptions.minPrice,
                maxPrice: _filterOptions.maxPrice,
                inStockOnly: _filterOptions.inStockOnly,
                onSaleOnly: _filterOptions.onSaleOnly,
              )
              .where((product) => mergedRecommendations.contains(product))
              .toList();

      // Apply sorting
      mergedRecommendations = productProvider.sortProducts(
        mergedRecommendations,
        _filterOptions.sortBy,
      );
    } else {
      // Shuffle the merged recommendations for random display only when no filters
      mergedRecommendations.shuffle();
    }

    // Limit to 10 items for better performance
    mergedRecommendations = mergedRecommendations.take(15).toList();

    if (mergedRecommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.recommend, color: AppColors.secondary),
              const SizedBox(width: 8),
              const Text(
                'Recommended for You',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_filterOptions.hasActiveFilters) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Filtered',
                    style: TextStyle(fontSize: 10, color: AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            authProvider.currentUser != null
                ? 'Personalized picks and trending items'
                : 'Popular and trending items',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: mergedRecommendations.length,
              itemBuilder: (context, index) {
                return _buildProductCard(
                  mergedRecommendations[index],
                  horizontal: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return SafeArea(
          child: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _refreshData,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // Location banner
                SliverToBoxAdapter(child: _buildLocationBanner()),

                // Search bar
                SliverToBoxAdapter(child: _buildSearchBar()),

                // Show search results, filtered results, or normal sections
                if (_isSearchActive) ...[
                  // Show search results when search is active
                  SliverToBoxAdapter(child: _buildSearchResultsSection()),
                ] else if (_filterOptions.hasActiveFilters) ...[
                  // Only show filtered products when filters are active
                  SliverToBoxAdapter(child: _buildFilteredProductsSection()),
                ] else ...[
                  // Show normal sections when no filters are applied
                  // Merged Recommendations (only for authenticated users)
                  if (authProvider.currentUser != null)
                    SliverToBoxAdapter(
                      child: _buildMergedRecommendationsSection(),
                    ),

                  // Popular Products
                  SliverToBoxAdapter(child: _buildPopularProductsSection()),

                  // All Products by Category
                  SliverToBoxAdapter(child: _buildProductsByCategory()),
                ],

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for products...',
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon:
              _isSearchActive
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: _clearSearch,
                  )
                  : Container(
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(51),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: AppColors.secondary,
                      size: 18,
                    ),
                  ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: _performSearch,
        onChanged: (value) {
          if (value.isEmpty) {
            _clearSearch();
          } else {
            _performSearch(value);
          }
        },
      ),
    );
  }

  Widget _buildSearchResultsSection() {
    if (_isSearching) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    // Get matching categories
    final matchingCategories =
        productProvider.categories.where((category) {
          return category.name.toLowerCase().contains(_searchQuery);
        }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search header
          Row(
            children: [
              const Icon(Icons.search, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Search Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'for "$_searchQuery"',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Show matching categories first
          if (matchingCategories.isNotEmpty) ...[
            const Text(
              'Categories',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: matchingCategories.length,
                itemBuilder: (context, index) {
                  final category = matchingCategories[index];
                  return _buildCategoryCard(category);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Show products
          if (_searchResults.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Products',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_searchResults.length} found',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ResponsiveGrid.getCrossAxisCount(
                      screenWidth,
                    ),
                    childAspectRatio: ResponsiveGrid.getChildAspectRatio(
                      screenWidth,
                    ),
                    crossAxisSpacing: ResponsiveGrid.getSpacing(screenWidth),
                    mainAxisSpacing: ResponsiveGrid.getSpacing(screenWidth),
                  ),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(_searchResults[index]);
                  },
                );
              },
            ),
          ] else if (!_isSearching) ...[
            // No results found
            Container(
              padding: const EdgeInsets.all(32),
              child: const Column(
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No products found',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try searching with different keywords',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryCard(dynamic category) {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            final products = productProvider.getProductsByCategory(category.id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ProductListScreen(
                      title: category.name,
                      products: products,
                      categoryId: category.id,
                    ),
              ),
            );
          },
          child: Column(
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(51),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    category.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.category, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredProductsSection() {
    final productProvider = Provider.of<ProductProvider>(context);

    // Get all filtered products
    List<ProductModel> filteredProducts = productProvider.filterProducts(
      categoryId: _filterOptions.categoryId,
      minPrice: _filterOptions.minPrice,
      maxPrice: _filterOptions.maxPrice,
      inStockOnly: _filterOptions.inStockOnly,
      onSaleOnly: _filterOptions.onSaleOnly,
    );

    // Apply sorting
    filteredProducts = productProvider.sortProducts(
      filteredProducts,
      _filterOptions.sortBy,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Filtered Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${filteredProducts.length} products',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getFilterDescription(),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (filteredProducts.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: const Column(
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No products found',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try adjusting your filters to see more results',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ResponsiveGrid.getCrossAxisCount(
                      screenWidth,
                    ),
                    childAspectRatio: ResponsiveGrid.getChildAspectRatio(
                      screenWidth,
                    ),
                    crossAxisSpacing: ResponsiveGrid.getSpacing(screenWidth),
                    mainAxisSpacing: ResponsiveGrid.getSpacing(screenWidth),
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(filteredProducts[index]);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  String _getFilterDescription() {
    List<String> descriptions = [];

    if (_filterOptions.categoryId != null) {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      final category = productProvider.categories.firstWhere(
        (cat) => cat.id == _filterOptions.categoryId,
        orElse: () => throw Exception('Category not found'),
      );
      descriptions.add('Category: ${category.name}');
    }

    if (_filterOptions.minPrice != null || _filterOptions.maxPrice != null) {
      String priceRange = 'Price: ';
      if (_filterOptions.minPrice != null && _filterOptions.maxPrice != null) {
        priceRange +=
            '₹${_filterOptions.minPrice!.toStringAsFixed(0)} - ₹${_filterOptions.maxPrice!.toStringAsFixed(0)}';
      } else if (_filterOptions.minPrice != null) {
        priceRange += 'Above ₹${_filterOptions.minPrice!.toStringAsFixed(0)}';
      } else {
        priceRange += 'Below ₹${_filterOptions.maxPrice!.toStringAsFixed(0)}';
      }
      descriptions.add(priceRange);
    }

    if (_filterOptions.inStockOnly == true) {
      descriptions.add('In stock only');
    }

    if (_filterOptions.onSaleOnly == true) {
      descriptions.add('On sale only');
    }

    descriptions.add('Sorted by: ${_getSortDescription()}');

    return descriptions.join(' • ');
  }

  String _getSortDescription() {
    switch (_filterOptions.sortBy) {
      case 'name':
        return 'Name (A-Z)';
      case 'price_low':
        return 'Price (Low to High)';
      case 'price_high':
        return 'Price (High to Low)';
      case 'popularity':
        return 'Popularity';
      default:
        return 'Name (A-Z)';
    }
  }

  Widget _buildPopularProductsSection() {
    final productProvider = Provider.of<ProductProvider>(context);
    List<ProductModel> popularProducts = productProvider.getPopularProducts();

    // Apply filters if active
    if (_filterOptions.hasActiveFilters) {
      popularProducts =
          productProvider
              .filterProducts(
                categoryId: _filterOptions.categoryId,
                minPrice: _filterOptions.minPrice,
                maxPrice: _filterOptions.maxPrice,
                inStockOnly: _filterOptions.inStockOnly,
                onSaleOnly: _filterOptions.onSaleOnly,
              )
              .where((product) => popularProducts.contains(product))
              .toList();

      // Apply sorting
      popularProducts = productProvider.sortProducts(
        popularProducts,
        _filterOptions.sortBy,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Popular Products',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (_filterOptions.hasActiveFilters) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Filtered',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(
                width: 80,
                child: TextButton(
                  onPressed: () {
                    // Navigate to all popular products
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProductListScreen(
                              title: 'Popular Products',
                              products: productProvider.getPopularProducts(),
                              isPopular: true,
                            ),
                      ),
                    );
                  },
                  child: const Text('See all'),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child:
              popularProducts.isEmpty
                  ? const Center(child: Text('No popular products available'))
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: popularProducts.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(
                        popularProducts[index],
                        horizontal: true,
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildProductsByCategory() {
    final productProvider = Provider.of<ProductProvider>(context);
    final categories = productProvider.categories;

    return Column(
      children:
          categories.map((category) {
            List<ProductModel> products = productProvider.getProductsByCategory(
              category.id,
            );

            // Apply filters if active
            if (_filterOptions.hasActiveFilters) {
              products =
                  productProvider
                      .filterProducts(
                        categoryId: _filterOptions.categoryId,
                        minPrice: _filterOptions.minPrice,
                        maxPrice: _filterOptions.maxPrice,
                        inStockOnly: _filterOptions.inStockOnly,
                        onSaleOnly: _filterOptions.onSaleOnly,
                      )
                      .where((product) => products.contains(product))
                      .toList();

              // Apply sorting
              products = productProvider.sortProducts(
                products,
                _filterOptions.sortBy,
              );
            }

            if (products.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_filterOptions.hasActiveFilters) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Filtered',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(
                        width: 80,
                        child: TextButton(
                          onPressed: () {
                            // Navigate to all products in this category
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ProductListScreen(
                                      title: category.name,
                                      products: productProvider
                                          .getProductsByCategory(category.id),
                                      categoryId: category.id,
                                    ),
                              ),
                            );
                          },
                          child: const Text('See all'),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: products.length > 6 ? 6 : products.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(
                        products[index],
                        horizontal: true,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildProductCard(ProductModel product, {bool horizontal = false}) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (horizontal) {
      // Horizontal card for scrolling lists
      return Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(product: product),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      child: Image.network(
                        product.imageUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                    ),
                    // Out of stock overlay
                    if (product.stock <= 0)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(128),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppPadding.medium,
                              vertical: AppPadding.small,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.small,
                              ),
                            ),
                            child: Text(
                              'OUT OF STOCK',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Low stock indicator
                    if (product.stock > 0 && product.stock < 5)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.small,
                            ),
                          ),
                          child: Text(
                            'Low Stock: ${product.stock}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        product.unit,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${(product.discountPrice ?? product.price).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap:
                                  product.stock > 0
                                      ? () {
                                        // Use a synchronous approach to avoid BuildContext issues
                                        cartProvider.addToCart(product, 1).then((
                                          success,
                                        ) {
                                          if (mounted) {
                                            if (success) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '${product.name} added to cart',
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 1,
                                                  ),
                                                ),
                                              );
                                            } else if (cartProvider.error !=
                                                null) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    cartProvider.error!,
                                                  ),
                                                  backgroundColor:
                                                      AppColors.error,
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        });
                                      }
                                      : null, // Disable if out of stock
                              child: Ink(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color:
                                      product.stock > 0
                                          ? AppColors.primary
                                          : Colors.grey,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  product.stock > 0
                                      ? Icons.add
                                      : Icons.remove_shopping_cart,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Grid card for category sections - now using the same style as horizontal cards
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(product: product),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: Image.network(
                  product.imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.unit,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${(product.discountPrice ?? product.price).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () {
                              cartProvider.addToCart(product, 1);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${product.name} added to cart',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Ink(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHomeAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Smart Kirana',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14),
              const SizedBox(width: 4),
              Text(
                'Delivery in $_deliveryTime',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),

      actions: [
        // Filter button
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.filter_list),
              if (_filterOptions.hasActiveFilters)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: _showFilterDialog,
          tooltip: 'Filter Products',
        ),

        // Sort button
        PopupMenuButton<String>(
          icon: Stack(
            children: [
              const Icon(Icons.sort),
              if (_filterOptions.sortBy != 'name')
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
            ],
          ),
          tooltip: 'Sort Products',
          onSelected: (value) {
            setState(() {
              _filterOptions = _filterOptions.copyWith(sortBy: value);
            });
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(value: 'name', child: Text('Name (A-Z)')),
                const PopupMenuItem(
                  value: 'price_low',
                  child: Text('Price (Low to High)'),
                ),
                const PopupMenuItem(
                  value: 'price_high',
                  child: Text('Price (High to Low)'),
                ),
                const PopupMenuItem(
                  value: 'popularity',
                  child: Text('Popularity'),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return const Text('Products');
      case 1:
        return const Text('Cart');
      case 2:
        return const Text('Profile');
      default:
        return const Text('Smart Kirana');
    }
  }

  List<Widget> _buildAppBarActions() {
    return [];
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading...'),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Error', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(_errorMessage, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _refreshData, child: const Text('Retry')),
        ],
      ),
    );
  }
}
