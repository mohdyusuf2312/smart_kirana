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
import 'package:smart_kirana/screens/home/search_screen.dart';
import 'package:smart_kirana/services/location_service.dart';
import 'package:smart_kirana/utils/constants.dart';

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

  Widget _buildUserRecommendationsSection() {
    final productProvider = Provider.of<ProductProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final recommendationProvider = Provider.of<RecommendationProvider>(context);

    // Check if user is logged in
    final isLoggedIn = authProvider.currentUser != null;

    // Only show user recommendations if user is logged in
    if (!isLoggedIn ||
        recommendationProvider.userRecommendations == null ||
        recommendationProvider.userRecommendations!.products.isEmpty) {
      // Return empty container if no user recommendations
      return const SizedBox.shrink();
    }

    // Convert recommendation products to product models
    List<ProductModel> recommendedProducts = [];
    final recommendations =
        recommendationProvider.userRecommendations!.products;
    for (var recommendation in recommendations) {
      final product = productProvider.getProductById(recommendation.productId);
      if (product != null) {
        recommendedProducts.add(product);
      }
    }

    // If no valid products found, return empty container
    if (recommendedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person, color: AppColors.secondary),
              SizedBox(width: 8),
              Text(
                'Recommended for You',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Based on your previous orders',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: recommendedProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(
                  recommendedProducts[index],
                  horizontal: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalRecommendationsSection() {
    final productProvider = Provider.of<ProductProvider>(context);
    final recommendationProvider = Provider.of<RecommendationProvider>(context);

    // Get global recommendations
    List<ProductModel> recommendedProducts = [];
    String recommendationSource = 'popular products';

    // Try global recommendations first
    if (recommendationProvider.globalRecommendations != null &&
        recommendationProvider.globalRecommendations!.products.isNotEmpty) {
      final globalRecs = recommendationProvider.globalRecommendations!.products;
      for (var recommendation in globalRecs) {
        final product = productProvider.getProductById(
          recommendation.productId,
        );
        if (product != null) {
          recommendedProducts.add(product);
        }
      }

      if (recommendedProducts.isNotEmpty) {
        recommendationSource = 'popular items';
      }
    }

    // If no global recommendations, fall back to popular products
    if (recommendedProducts.isEmpty) {
      recommendedProducts =
          productProvider.getPopularProducts().take(5).toList();
      recommendationSource = 'popular products';
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.secondary),
              SizedBox(width: 8),
              Text(
                'Popular Recommendations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Based on $recommendationSource',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child:
                recommendedProducts.isEmpty
                    ? const Center(child: Text('No recommendations available'))
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: recommendedProducts.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(
                          recommendedProducts[index],
                          horizontal: true,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final productProvider = Provider.of<ProductProvider>(context);
    final categories = productProvider.categories;

    // ✅ Filter categories that have at least one product
    final categoriesWithProducts =
        categories
            .where(
              (category) =>
                  productProvider.getProductsByCategory(category.id).isNotEmpty,
            )
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shop by Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (categoriesWithProducts.length > 5)
                SizedBox(
                  width: 80,
                  child: TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('All Categories'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: categoriesWithProducts.length,
                                  itemBuilder: (context, index) {
                                    final category =
                                        categoriesWithProducts[index];
                                    final products = productProvider
                                        .getProductsByCategory(category.id);
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          category.imageUrl,
                                        ),
                                        onBackgroundImageError: (_, __) {},
                                        backgroundColor: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.category,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      title: Text(category.name),
                                      subtitle: Text(
                                        '${products.length} products',
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
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
                                    );
                                  },
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                      );
                    },
                    child: const Text('See all'),
                  ),
                ),
            ],
          ),
        ),
        Container(
          height: 125,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              categoriesWithProducts.isEmpty
                  ? const Center(child: Text('No categories available'))
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: categoriesWithProducts.length,
                    itemBuilder: (context, index) {
                      final category = categoriesWithProducts[index];
                      return _buildCategoryItem(category);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(dynamic category) {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final products = productProvider.getProductsByCategory(category.id);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            if (products.isNotEmpty) {
              // Navigate to category products screen
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
            } else {
              // Show message if no products in this category
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No products available in this category'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
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
                    borderRadius: BorderRadius.circular(30),
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
                SizedBox(
                  width: 80,
                  child: Text(
                    category.name,
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
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

            // User-specific Recommendations (only shown if user is logged in and has recommendations)
            SliverToBoxAdapter(child: _buildUserRecommendationsSection()),

            // Global Recommendations (shown to all users)
            SliverToBoxAdapter(child: _buildGlobalRecommendationsSection()),

            // Categories
            SliverToBoxAdapter(child: _buildCategoriesSection()),

            // Popular Products
            SliverToBoxAdapter(child: _buildPopularProductsSection()),

            // All Products by Category
            SliverToBoxAdapter(child: _buildProductsByCategory()),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularProductsSection() {
    final productProvider = Provider.of<ProductProvider>(context);
    final popularProducts = productProvider.getPopularProducts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Products',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                              products: popularProducts,
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
            final products = productProvider.getProductsByCategory(category.id);
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
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                                      products: products,
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text(
                      'Search for products...',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(4),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.location_on),
          onPressed: () {
            // Show location dialog
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Delivery Location'),
                    content: Text(_deliveryLocation),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          // Refresh location
                          await _initializeLocation();
                        },
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
            );
          },
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
    if (_currentIndex == 0) {
      return [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
        ),
      ];
    }
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
