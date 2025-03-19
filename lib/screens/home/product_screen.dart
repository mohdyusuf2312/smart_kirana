import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/providers/cart_provider.dart';
import 'package:smart_kirana/providers/product_provider.dart';
import 'package:smart_kirana/screens/home/product_detail_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/cart_summary_bar.dart';
import 'package:smart_kirana/widgets/product_card.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    await productProvider.loadCategories();
    await productProvider.loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final categories = [
      'All',
      ...productProvider.categories.map((c) => c.name),
    ];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child:
            productProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    // Category Selector
                    Container(
                      height: 50,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = category == _selectedCategory;

                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? AppColors.primary
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    AppBorderRadius.medium,
                                  ),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppColors.primary
                                            : AppColors.textSecondary.withAlpha(
                                              76,
                                            ),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Products Grid
                    Expanded(
                      child:
                          productProvider.products.isEmpty
                              ? const Center(
                                child: Text('No products available'),
                              )
                              : GridView.builder(
                                padding: const EdgeInsets.only(
                                  left: AppPadding.medium,
                                  right: AppPadding.medium,
                                  top: AppPadding.medium,
                                  bottom:
                                      80, // Extra padding for cart summary bar
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.75,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                itemCount:
                                    _getFilteredProducts(
                                      productProvider.products,
                                    ).length,
                                itemBuilder: (context, index) {
                                  final product =
                                      _getFilteredProducts(
                                        productProvider.products,
                                      )[index];
                                  return ProductCard(
                                    product: product,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ProductDetailScreen(
                                                product: product,
                                              ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                    ),
                  ],
                ),
      ),
      bottomNavigationBar: const CartSummaryBar(),
    );
  }

  List<ProductModel> _getFilteredProducts(List<ProductModel> products) {
    if (_selectedCategory == 'All') {
      return products;
    }
    return products
        .where((product) => product.categoryName == _selectedCategory)
        .toList();
  }
}
