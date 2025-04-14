import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/providers/cart_provider.dart';
import 'package:smart_kirana/providers/product_provider.dart';
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
  String _deliveryLocation = 'Fetching location...';
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
      // Initialize location service
      await _initializeLocation();

      // Load products and categories
      if (mounted) {
        await _loadProductData();
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

  Future<void> _initializeLocation() async {
    try {
      bool initialized = await _locationService.initialize();
      if (initialized && mounted) {
        setState(() {
          _deliveryLocation =
              _locationService.currentAddress ?? 'Location not available';
          _deliveryTime = _locationService.getEstimatedDeliveryTime();
        });
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
      // Don't set error message here to avoid blocking the whole screen
      // Just keep the default location message
    }
  }

  // Authentication is now handled by HomeWrapper

  Future<void> _loadProductData() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    try {
      await productProvider.loadCategories();
      await productProvider.loadProducts();
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 16, color: AppColors.secondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _deliveryLocation,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  _deliveryTime,
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final productProvider = Provider.of<ProductProvider>(context);
    final recommendedProducts =
        productProvider.getPopularProducts().take(5).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.secondary),
              SizedBox(width: 8),
              Text(
                'Recommended for you',
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
            child:
                recommendedProducts.isEmpty
                    ? const Center(child: Text('No recommendations yet'))
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
              // View all categories button
              if (categories.length > 5)
                SizedBox(
                  width: 80,
                  child: TextButton(
                    onPressed: () {
                      // Show all categories in a dialog
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('All Categories'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: categories.length,
                                  itemBuilder: (context, index) {
                                    final category = categories[index];
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
                                        if (products.isNotEmpty) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      ProductListScreen(
                                                        title: category.name,
                                                        products: products,
                                                        categoryId: category.id,
                                                      ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'No products available in this category',
                                              ),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        }
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
              categories.isEmpty
                  ? const Center(child: Text('No categories available'))
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
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

            // AI Recommendations
            SliverToBoxAdapter(child: _buildRecommendationsSection()),

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
