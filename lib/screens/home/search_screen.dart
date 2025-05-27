import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/providers/product_provider.dart';
import 'package:smart_kirana/screens/home/product_detail_screen.dart';
import 'package:smart_kirana/screens/home/product_list_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<ProductModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
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
          final nameMatch = product.name.toLowerCase().contains(query);
          final descriptionMatch = product.description.toLowerCase().contains(
            query,
          );
          final categoryMatch = product.categoryName.toLowerCase().contains(
            query,
          );
          return nameMatch || descriptionMatch || categoryMatch;
        }).toList();

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search products...',
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            filled: true,
            fillColor: Colors.white24,
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: Colors.white70),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchResults = [];
                });
              },
            ),
          ),
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _performSearch(),
          onChanged: (value) {
            if (value.isEmpty) {
              setState(() {
                _searchResults = [];
              });
            } else {
              // Perform search as user types
              _performSearch();
            }
          },
        ),
        backgroundColor: AppColors.primary,
      ),
      body:
          _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
              ? _buildEmptyState()
              : _buildSearchResults(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isEmpty ? Icons.search : Icons.search_off,
            size: 100,
            color: AppColors.textSecondary.withAlpha(128),
          ),
          const SizedBox(height: AppPadding.medium),
          Text(
            _searchController.text.isEmpty
                ? 'Search for products'
                : 'No products found',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppPadding.small),
          Text(
            _searchController.text.isEmpty
                ? 'Enter a search term to find products'
                : 'Try a different search term',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final query = _searchController.text.trim().toLowerCase();

    // Get matching categories
    final matchingCategories =
        productProvider.categories.where((category) {
          return category.name.toLowerCase().contains(query);
        }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show matching categories first
          if (matchingCategories.isNotEmpty) ...[
            const Text(
              'Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    final product = _searchResults[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    ProductDetailScreen(product: product),
                          ),
                        );
                      },
                    );
                  },
                );
              },
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
}
