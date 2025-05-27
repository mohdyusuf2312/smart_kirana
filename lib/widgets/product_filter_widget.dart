import 'package:flutter/material.dart';
import 'package:smart_kirana/models/category_model.dart';
import 'package:smart_kirana/utils/constants.dart';

class ProductFilterOptions {
  String? categoryId;
  double? minPrice;
  double? maxPrice;
  bool? inStockOnly;
  bool? onSaleOnly;
  String sortBy; // 'name', 'price_low', 'price_high', 'popularity'

  ProductFilterOptions({
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.inStockOnly,
    this.onSaleOnly,
    this.sortBy = 'name',
  });

  ProductFilterOptions copyWith({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    bool? onSaleOnly,
    String? sortBy,
  }) {
    return ProductFilterOptions(
      categoryId: categoryId ?? this.categoryId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      onSaleOnly: onSaleOnly ?? this.onSaleOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasActiveFilters {
    return categoryId != null ||
        minPrice != null ||
        maxPrice != null ||
        inStockOnly == true ||
        onSaleOnly == true ||
        sortBy != 'name'; // Include sorting as an active filter
  }

  void clear() {
    categoryId = null;
    minPrice = null;
    maxPrice = null;
    inStockOnly = null;
    onSaleOnly = null;
    sortBy = 'name';
  }
}

class ProductFilterWidget extends StatefulWidget {
  final ProductFilterOptions initialFilters;
  final List<CategoryModel> categories;
  final Function(ProductFilterOptions) onFiltersChanged;

  const ProductFilterWidget({
    super.key,
    required this.initialFilters,
    required this.categories,
    required this.onFiltersChanged,
  });

  @override
  State<ProductFilterWidget> createState() => _ProductFilterWidgetState();
}

class _ProductFilterWidgetState extends State<ProductFilterWidget> {
  late ProductFilterOptions _filters;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = ProductFilterOptions(
      categoryId: widget.initialFilters.categoryId,
      minPrice: widget.initialFilters.minPrice,
      maxPrice: widget.initialFilters.maxPrice,
      inStockOnly: widget.initialFilters.inStockOnly,
      onSaleOnly: widget.initialFilters.onSaleOnly,
      sortBy: widget.initialFilters.sortBy,
    );

    if (_filters.minPrice != null) {
      _minPriceController.text = _filters.minPrice!.toStringAsFixed(0);
    }
    if (_filters.maxPrice != null) {
      _maxPriceController.text = _filters.maxPrice!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.large),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter Products', style: AppTextStyles.heading2),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear All'),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),

              // Category Filter
              _buildCategoryFilter(),
              const SizedBox(height: AppPadding.medium),

              // Price Range Filter
              _buildPriceRangeFilter(),
              const SizedBox(height: AppPadding.medium),

              // Stock and Sale Filters
              _buildStockAndSaleFilters(),
              const SizedBox(height: AppPadding.medium),

              // Sort Options
              // _buildSortOptions(),
              // const SizedBox(height: AppPadding.large),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppPadding.medium,
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              // Add bottom padding to prevent overflow
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: AppTextStyles.bodyLarge),
        const SizedBox(height: AppPadding.small),
        DropdownButtonFormField<String>(
          value: _filters.categoryId,
          decoration: const InputDecoration(
            hintText: 'All Categories',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Categories'),
            ),
            ...widget.categories.map(
              (category) => DropdownMenuItem<String>(
                value: category.id,
                child: Text(category.name),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _filters.categoryId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Price Range (₹)', style: AppTextStyles.bodyLarge),
        const SizedBox(height: AppPadding.small),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Min Price',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                onChanged: (value) {
                  _filters.minPrice = double.tryParse(value);
                },
              ),
            ),
            const SizedBox(width: AppPadding.small),
            const Text('to'),
            const SizedBox(width: AppPadding.small),
            Expanded(
              child: TextFormField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Max Price',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                onChanged: (value) {
                  _filters.maxPrice = double.tryParse(value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStockAndSaleFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Availability', style: AppTextStyles.bodyLarge),
        const SizedBox(height: AppPadding.small),
        CheckboxListTile(
          title: const Text('In Stock Only'),
          value: _filters.inStockOnly ?? false,
          onChanged: (value) {
            setState(() {
              _filters.inStockOnly = value;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('On Sale Only'),
          value: _filters.onSaleOnly ?? false,
          onChanged: (value) {
            setState(() {
              _filters.onSaleOnly = value;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  // Widget _buildSortOptions() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text('Sort By', style: AppTextStyles.bodyLarge),
  //       const SizedBox(height: AppPadding.small),
  //       DropdownButtonFormField<String>(
  //         value: _filters.sortBy,
  //         decoration: const InputDecoration(border: OutlineInputBorder()),
  //         items: const [
  //           DropdownMenuItem(value: 'name', child: Text('Name (A-Z)')),
  //           DropdownMenuItem(
  //             value: 'price_low',
  //             child: Text('Price (Low to High)'),
  //           ),
  //           DropdownMenuItem(
  //             value: 'price_high',
  //             child: Text('Price (High to Low)'),
  //           ),
  //           DropdownMenuItem(value: 'popularity', child: Text('Popularity')),
  //         ],
  //         onChanged: (value) {
  //           setState(() {
  //             _filters.sortBy = value ?? 'name';
  //           });
  //         },
  //       ),
  //     ],
  //   );
  // }

  void _clearFilters() {
    setState(() {
      _filters.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
    Navigator.pop(context);
  }
}
