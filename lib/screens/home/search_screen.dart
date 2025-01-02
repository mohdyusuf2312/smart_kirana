import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/providers/product_provider.dart';
import 'package:smart_kirana/screens/home/product_detail_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({
    super.key,
    this.initialQuery,
  });

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

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final allProducts = productProvider.products;

    // Filter products based on search query
    final results = allProducts.where((product) {
      final nameMatch = product.name.toLowerCase().contains(query);
      final descriptionMatch = product.description.toLowerCase().contains(query);
      final categoryMatch = product.categoryName.toLowerCase().contains(query);
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
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
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
            }
          },
        ),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _performSearch,
          ),
        ],
      ),
      body: _isSearching
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
            _searchController.text.isEmpty
                ? Icons.search
                : Icons.search_off,
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
    return GridView.builder(
      padding: const EdgeInsets.all(AppPadding.medium),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
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
                builder: (context) => ProductDetailScreen(product: product),
              ),
            );
          },
        );
      },
    );
  }
}
