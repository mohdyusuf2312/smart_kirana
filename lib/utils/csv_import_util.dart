import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:smart_kirana/models/product_model.dart';

/// Utility class for importing products from CSV files
class CSVImportUtil {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Import products from a CSV file
  /// Returns a map with import results
  Future<Map<String, dynamic>> importProductsFromCSV(
    File csvFile, {
    bool skipHeader = true,
  }) async {
    final List<String> errors = [];
    final List<String> warnings = [];
    int importedCount = 0;
    int skippedCount = 0;

    try {
      // Read the CSV file
      final input = await csvFile.readAsString();
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(
        input,
      );

      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Skip header if needed
      final dataRows =
          skipHeader && csvData.length > 1 ? csvData.sublist(1) : csvData;

      if (dataRows.isEmpty) {
        throw Exception('No data rows found in CSV file');
      }

      // Get all categories to match by name
      final categoriesSnapshot =
          await _firestore.collection('categories').get();

      if (categoriesSnapshot.docs.isEmpty) {
        throw Exception(
          'No categories found in database. Please add categories first.',
        );
      }

      final Map<String, String> categoryNameToId = {};
      final Map<String, String> categoryIdToName = {};

      for (var doc in categoriesSnapshot.docs) {
        final data = doc.data();
        final name = data['name']?.toString() ?? '';
        if (name.isNotEmpty) {
          categoryNameToId[name.toLowerCase()] = doc.id;
          categoryIdToName[doc.id] = name;
        }
      }

      // Process each row
      for (var i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        final rowIndex =
            skipHeader ? i + 2 : i + 1; // For error reporting (1-based index)

        try {
          if (row.length < 7) {
            warnings.add(
              'Row $rowIndex: Insufficient columns (${row.length}), minimum 7 required. Skipping row.',
            );
            skippedCount++;
            continue;
          }

          // Extract data from CSV row
          final name = row[0].toString().trim();
          if (name.isEmpty) {
            warnings.add('Row $rowIndex: Product name is empty. Skipping row.');
            skippedCount++;
            continue;
          }

          final description = row[1].toString().trim();

          // Parse price with error handling
          final priceStr = row[2].toString().trim();
          double price;
          try {
            price = double.parse(priceStr);
            if (price < 0) {
              warnings.add(
                'Row $rowIndex: Negative price ($price) for product "$name". Setting to 0.',
              );
              price = 0;
            }
          } catch (e) {
            warnings.add(
              'Row $rowIndex: Invalid price format "$priceStr" for product "$name". Setting to 0.',
            );
            price = 0;
          }

          // Parse discount price with error handling
          double? discountPrice;
          final discountPriceStr = row[3].toString().trim();
          if (discountPriceStr.isNotEmpty) {
            try {
              discountPrice = double.parse(discountPriceStr);
              if (discountPrice < 0) {
                warnings.add(
                  'Row $rowIndex: Negative discount price ($discountPrice) for product "$name". Setting to null.',
                );
                discountPrice = null;
              } else if (discountPrice > price) {
                warnings.add(
                  'Row $rowIndex: Discount price ($discountPrice) is greater than regular price ($price) for product "$name".',
                );
              }
            } catch (e) {
              warnings.add(
                'Row $rowIndex: Invalid discount price format "$discountPriceStr" for product "$name". Setting to null.',
              );
              discountPrice = null;
            }
          }

          final imageUrl = row[4].toString().trim();
          final categoryName = row[5].toString().trim();

          // Parse stock with error handling
          final stockStr = row[6].toString().trim();
          int stock;
          try {
            stock = int.parse(stockStr);
            if (stock < 0) {
              warnings.add(
                'Row $rowIndex: Negative stock ($stock) for product "$name". Setting to 0.',
              );
              stock = 0;
            }
          } catch (e) {
            warnings.add(
              'Row $rowIndex: Invalid stock format "$stockStr" for product "$name". Setting to 0.',
            );
            stock = 0;
          }

          final unit = row.length > 7 ? row[7].toString().trim() : '';

          // Parse boolean fields
          bool isPopular = false;
          if (row.length > 8) {
            final isPopularStr = row[8].toString().trim().toLowerCase();
            isPopular =
                isPopularStr == 'true' ||
                isPopularStr == 'yes' ||
                isPopularStr == '1';
          }

          bool isFeatured = false;
          if (row.length > 9) {
            final isFeaturedStr = row[9].toString().trim().toLowerCase();
            isFeatured =
                isFeaturedStr == 'true' ||
                isFeaturedStr == 'yes' ||
                isFeaturedStr == '1';
          }

          // Find category ID from name (case insensitive)
          String? categoryId = categoryNameToId[categoryName.toLowerCase()];

          // Skip if category not found
          if (categoryId == null) {
            warnings.add(
              'Row $rowIndex: Category "$categoryName" not found for product "$name". Skipping row.',
            );
            skippedCount++;
            continue;
          }

          // Create product data
          final productData = {
            'name': name,
            'description': description,
            'price': price,
            'discountPrice': discountPrice,
            'imageUrl': imageUrl,
            'categoryId': categoryId,
            'categoryName': categoryIdToName[categoryId] ?? categoryName,
            'stock': stock,
            'unit': unit,
            'isPopular': isPopular,
            'isFeatured': isFeatured,
            'createdAt': FieldValue.serverTimestamp(),
          };

          // Add to Firestore
          await _firestore.collection('products').add(productData);
          importedCount++;
        } catch (e) {
          errors.add('Row $rowIndex: Failed to process row: $e');
          skippedCount++;
        }
      }

      return {
        'success': true,
        'importedCount': importedCount,
        'skippedCount': skippedCount,
        'errors': errors,
        'warnings': warnings,
      };
    } catch (e) {
      debugPrint('Error importing products from CSV: $e');
      return {
        'success': false,
        'importedCount': importedCount,
        'skippedCount': skippedCount,
        'errors': [...errors, e.toString()],
        'warnings': warnings,
      };
    }
  }

  /// Import products from a CSV file with image uploads
  /// The CSV should have image file names in the image column
  /// The image files should be in the same directory as the CSV file
  Future<Map<String, dynamic>> importProductsWithImages(
    File csvFile,
    List<File> imageFiles, {
    bool skipHeader = true,
  }) async {
    final List<String> errors = [];
    final List<String> warnings = [];
    int importedCount = 0;
    int skippedCount = 0;

    try {
      // Read the CSV file
      final input = await csvFile.readAsString();
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(
        input,
      );

      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Skip header if needed
      final dataRows =
          skipHeader && csvData.length > 1 ? csvData.sublist(1) : csvData;

      if (dataRows.isEmpty) {
        throw Exception('No data rows found in CSV file');
      }

      // Get all categories to match by name
      final categoriesSnapshot =
          await _firestore.collection('categories').get();

      if (categoriesSnapshot.docs.isEmpty) {
        throw Exception(
          'No categories found in database. Please add categories first.',
        );
      }

      final Map<String, String> categoryNameToId = {};
      final Map<String, String> categoryIdToName = {};

      for (var doc in categoriesSnapshot.docs) {
        final data = doc.data();
        final name = data['name']?.toString() ?? '';
        if (name.isNotEmpty) {
          categoryNameToId[name.toLowerCase()] = doc.id;
          categoryIdToName[doc.id] = name;
        }
      }

      // Create a map of image file names to File objects (case insensitive)
      final Map<String, File> imageFileMap = {};
      for (var file in imageFiles) {
        final fileName = path.basename(file.path).toLowerCase();
        imageFileMap[fileName] = file;
      }

      // Process each row
      for (var i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        final rowIndex =
            skipHeader ? i + 2 : i + 1; // For error reporting (1-based index)

        try {
          if (row.length < 7) {
            warnings.add(
              'Row $rowIndex: Insufficient columns (${row.length}), minimum 7 required. Skipping row.',
            );
            skippedCount++;
            continue;
          }

          // Extract data from CSV row
          final name = row[0].toString().trim();
          if (name.isEmpty) {
            warnings.add('Row $rowIndex: Product name is empty. Skipping row.');
            skippedCount++;
            continue;
          }

          final description = row[1].toString().trim();

          // Parse price with error handling
          final priceStr = row[2].toString().trim();
          double price;
          try {
            price = double.parse(priceStr);
            if (price < 0) {
              warnings.add(
                'Row $rowIndex: Negative price ($price) for product "$name". Setting to 0.',
              );
              price = 0;
            }
          } catch (e) {
            warnings.add(
              'Row $rowIndex: Invalid price format "$priceStr" for product "$name". Setting to 0.',
            );
            price = 0;
          }

          // Parse discount price with error handling
          double? discountPrice;
          final discountPriceStr = row[3].toString().trim();
          if (discountPriceStr.isNotEmpty) {
            try {
              discountPrice = double.parse(discountPriceStr);
              if (discountPrice < 0) {
                warnings.add(
                  'Row $rowIndex: Negative discount price ($discountPrice) for product "$name". Setting to null.',
                );
                discountPrice = null;
              } else if (discountPrice > price) {
                warnings.add(
                  'Row $rowIndex: Discount price ($discountPrice) is greater than regular price ($price) for product "$name".',
                );
              }
            } catch (e) {
              warnings.add(
                'Row $rowIndex: Invalid discount price format "$discountPriceStr" for product "$name". Setting to null.',
              );
              discountPrice = null;
            }
          }

          final imageFileName = row[4].toString().trim();
          final categoryName = row[5].toString().trim();

          // Parse stock with error handling
          final stockStr = row[6].toString().trim();
          int stock;
          try {
            stock = int.parse(stockStr);
            if (stock < 0) {
              warnings.add(
                'Row $rowIndex: Negative stock ($stock) for product "$name". Setting to 0.',
              );
              stock = 0;
            }
          } catch (e) {
            warnings.add(
              'Row $rowIndex: Invalid stock format "$stockStr" for product "$name". Setting to 0.',
            );
            stock = 0;
          }

          final unit = row.length > 7 ? row[7].toString().trim() : '';

          // Parse boolean fields
          bool isPopular = false;
          if (row.length > 8) {
            final isPopularStr = row[8].toString().trim().toLowerCase();
            isPopular =
                isPopularStr == 'true' ||
                isPopularStr == 'yes' ||
                isPopularStr == '1';
          }

          bool isFeatured = false;
          if (row.length > 9) {
            final isFeaturedStr = row[9].toString().trim().toLowerCase();
            isFeatured =
                isFeaturedStr == 'true' ||
                isFeaturedStr == 'yes' ||
                isFeaturedStr == '1';
          }

          // Find category ID from name (case insensitive)
          String? categoryId = categoryNameToId[categoryName.toLowerCase()];

          // Skip if category not found
          if (categoryId == null) {
            warnings.add(
              'Row $rowIndex: Category "$categoryName" not found for product "$name". Skipping row.',
            );
            skippedCount++;
            continue;
          }

          // Upload image if available
          String imageUrl = '';
          if (imageFileName.isNotEmpty) {
            // Check if it's a URL
            if (imageFileName.startsWith('http')) {
              imageUrl = imageFileName;
            } else {
              // Try to find the image file (case insensitive)
              final imageFile = imageFileMap[imageFileName.toLowerCase()];
              if (imageFile != null) {
                try {
                  final storageRef = _storage.ref().child(
                    'products/${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}',
                  );
                  await storageRef.putFile(imageFile);
                  imageUrl = await storageRef.getDownloadURL();
                } catch (e) {
                  warnings.add(
                    'Row $rowIndex: Failed to upload image "$imageFileName" for product "$name": $e',
                  );
                }
              } else {
                warnings.add(
                  'Row $rowIndex: Image file "$imageFileName" not found for product "$name".',
                );
              }
            }
          }

          // Create product data
          final productData = {
            'name': name,
            'description': description,
            'price': price,
            'discountPrice': discountPrice,
            'imageUrl': imageUrl,
            'categoryId': categoryId,
            'categoryName': categoryIdToName[categoryId] ?? categoryName,
            'stock': stock,
            'unit': unit,
            'isPopular': isPopular,
            'isFeatured': isFeatured,
            'createdAt': FieldValue.serverTimestamp(),
          };

          // Add to Firestore
          await _firestore.collection('products').add(productData);
          importedCount++;
        } catch (e) {
          errors.add('Row $rowIndex: Failed to process row: $e');
          skippedCount++;
        }
      }

      return {
        'success': true,
        'importedCount': importedCount,
        'skippedCount': skippedCount,
        'errors': errors,
        'warnings': warnings,
      };
    } catch (e) {
      debugPrint('Error importing products with images: $e');
      return {
        'success': false,
        'importedCount': importedCount,
        'skippedCount': skippedCount,
        'errors': [...errors, e.toString()],
        'warnings': warnings,
      };
    }
  }
}
