import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_kirana/models/product_model.dart';
import 'package:smart_kirana/utils/constants.dart';

class ProductFormScreen extends StatefulWidget {
  final String? productId;

  const ProductFormScreen({Key? key, this.productId}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isEdit = false;
  File? _imageFile;
  String _imageUrl = '';
  List<String> _categories = [];
  String? _selectedCategoryId;

  // Form fields
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _unitController = TextEditingController();
  bool _isPopular = false;
  bool _isFeatured = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.productId != null;
    _loadCategories();
    if (_isEdit) {
      _loadProductData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categoriesSnapshot = await _firestore.collection('categories').get();
      final categories = categoriesSnapshot.docs;
      
      setState(() {
        _categories = categories.map((doc) => doc.data()['name'] as String).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
  }

  Future<void> _loadProductData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final productDoc = await _firestore.collection('products').doc(widget.productId).get();
      
      if (productDoc.exists) {
        final productData = productDoc.data() as Map<String, dynamic>;
        final product = ProductModel.fromMap(productData, productDoc.id);
        
        _nameController.text = product.name;
        _descriptionController.text = product.description;
        _priceController.text = product.price.toString();
        _discountPriceController.text = product.discountPrice?.toString() ?? '';
        _stockController.text = product.stock.toString();
        _unitController.text = product.unit;
        _isPopular = product.isPopular;
        _isFeatured = product.isFeatured;
        _imageUrl = product.imageUrl;
        _selectedCategoryId = product.categoryId;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load product data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage() async {
    if (_imageFile == null) return _imageUrl;
    
    try {
      final fileName = 'products/${DateTime.now().millisecondsSinceEpoch}_${_nameController.text.replaceAll(' ', '_')}';
      final ref = _storage.ref().child(fileName);
      
      await ref.putFile(_imageFile!);
      final url = await ref.getDownloadURL();
      
      return url;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return '';
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Upload image if selected
      final imageUrl = await _uploadImage();
      
      // Prepare product data
      final productData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'discountPrice': _discountPriceController.text.isNotEmpty
            ? double.parse(_discountPriceController.text)
            : null,
        'imageUrl': imageUrl,
        'categoryId': _selectedCategoryId,
        'stock': int.parse(_stockController.text),
        'unit': _unitController.text,
        'isPopular': _isPopular,
        'isFeatured': _isFeatured,
      };
      
      if (_isEdit) {
        // Update existing product
        await _firestore.collection('products').doc(widget.productId).update(productData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
        }
      } else {
        // Add new product
        await _firestore.collection('products').add(productData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully')),
          );
        }
      }
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save product: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Add Product'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppPadding.medium),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePicker(),
                    const SizedBox(height: AppPadding.large),
                    _buildFormFields(),
                    const SizedBox(height: AppPadding.large),
                    ElevatedButton(
                      onPressed: _saveProduct,
                      child: Text(_isEdit ? 'Update Product' : 'Add Product'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _imageFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  child: Image.file(
                    _imageFile!,
                    fit: BoxFit.cover,
                  ),
                )
              : _imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                      child: Image.network(
                        _imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.add_a_photo,
                      size: 50,
                      color: Colors.grey,
                    ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Product Name',
            hintText: 'Enter product name',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter product name';
            }
            return null;
          },
        ),
        const SizedBox(height: AppPadding.medium),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Enter product description',
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter product description';
            }
            return null;
          },
        ),
        const SizedBox(height: AppPadding.medium),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (₹)',
                  hintText: 'Enter price',
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppPadding.medium),
            Expanded(
              child: TextFormField(
                controller: _discountPriceController,
                decoration: const InputDecoration(
                  labelText: 'Discount Price (₹)',
                  hintText: 'Optional',
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (double.parse(value) >= double.parse(_priceController.text)) {
                      return 'Discount price should be less than regular price';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppPadding.medium),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Category',
            hintText: 'Select category',
          ),
          value: _selectedCategoryId,
          items: _categories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
        const SizedBox(height: AppPadding.medium),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  hintText: 'Enter stock quantity',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter stock quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppPadding.medium),
            Expanded(
              child: TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  hintText: 'e.g., kg, pcs',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter unit';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppPadding.medium),
        SwitchListTile(
          title: const Text('Popular Product'),
          subtitle: const Text('Show in popular products section'),
          value: _isPopular,
          onChanged: (value) {
            setState(() {
              _isPopular = value;
            });
          },
          activeColor: AppColors.primary,
        ),
        SwitchListTile(
          title: const Text('Featured Product'),
          subtitle: const Text('Show in featured products section'),
          value: _isFeatured,
          onChanged: (value) {
            setState(() {
              _isFeatured = value;
            });
          },
          activeColor: AppColors.primary,
        ),
      ],
    );
  }
}
