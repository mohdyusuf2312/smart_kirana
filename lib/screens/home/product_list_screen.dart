import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/providers/cart_provider.dart';
import 'package:smart_kirana/screens/home/product_detail_screen.dart';
import 'package:smart_kirana/utils/constants.dart';

class ProductListScreen extends StatefulWidget {
  final String title;
  final List<ProductModel> products;
  final bool isPopular;
  final String? categoryId;

  const ProductListScreen({
    Key? key,
    required this.title,
    required this.products,
    this.isPopular = false,
    this.categoryId,
  }) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late List<ProductModel> _products;
  bool _isLoading = false;
  String _sortBy = 'name'; // Default sort by name

  @override
  void initState() {
    super.initState();
    _products = List.from(widget.products);
    _sortProducts();
  }

  void _sortProducts() {
    setState(() {
      switch (_sortBy) {
        case 'name':
          _products.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'price_low':
          _products.sort((a, b) {
            final priceA = a.discountPrice ?? a.price;
            final priceB = b.discountPrice ?? b.price;
            return priceA.compareTo(priceB);
          });
          break;
        case 'price_high':
          _products.sort((a, b) {
            final priceA = a.discountPrice ?? a.price;
            final priceB = b.discountPrice ?? b.price;
            return priceB.compareTo(priceA);
          });
          break;
        case 'popularity':
          // For now, we'll just use the existing order for popularity
          // In a real app, you would have a popularity metric
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortProducts();
              });
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'name',
                    child: Text('Sort by Name'),
                  ),
                  const PopupMenuItem(
                    value: 'price_low',
                    child: Text('Price: Low to High'),
                  ),
                  const PopupMenuItem(
                    value: 'price_high',
                    child: Text('Price: High to Low'),
                  ),
                  const PopupMenuItem(
                    value: 'popularity',
                    child: Text('Sort by Popularity'),
                  ),
                ],
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
              ? const Center(child: Text('No products available'))
              : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio:
                      0.85, // Adjusted to match popular product cards
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(_products[index]);
                },
              ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Container(
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
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // debugPrint('Error loading image: $error');
                        return Container(
                          height: 100,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),
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
                        child: const Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${(product.discountPrice ?? product.price).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                            if (product.discountPrice != null)
                              Text(
                                '₹${product.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
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
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ADD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
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
}
