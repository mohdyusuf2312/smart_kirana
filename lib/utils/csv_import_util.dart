import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

/// Utility class for importing products from CSV files
class CSVImportUtil {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Web platform specific data
  String? _webCsvData;
  // ignore: unused_field
  String? _webCsvFileName;

  // Store web image files
  final Map<String, Uint8List> _webImageFiles = {};

  /// Set CSV data for web platform
  void setWebCsvData(String csvData, String fileName) {
    _webCsvData = csvData;
    _webCsvFileName = fileName;
  }

  /// Add web image file
  void addWebImageFile(String fileName, Uint8List bytes) {
    _webImageFiles[fileName.toLowerCase()] = bytes;
    // debugPrint('Added web image file: $fileName (${bytes.length} bytes)');
  }

  /// Clear web image files
  void clearWebImageFiles() {
    _webImageFiles.clear();
    // debugPrint('Cleared web image files');
  }

  /// Import products from a CSV file
  /// Returns a map with import results
  Future<Map<String, dynamic>> importProductsFromCSV(
    File csvFile, {
    bool skipHeader = true,
  }) async {
    final List<String> errors = [];
    final List<String> warnings = [];
    int importedCount = 0;
    int updatedCount = 0;
    int skippedCount = 0;

    try {
      // Read the CSV data - either from file or from web data
      String input;
      try {
        if (kIsWeb && _webCsvData != null) {
          // Use the web data if available
          input = _webCsvData!;
          // debugPrint('Using web CSV data: ${input.length} characters');
        } else {
          // Read from file for non-web platforms
          // debugPrint('Reading CSV file from path: ${csvFile.path}');
          // debugPrint('File exists: ${await csvFile.exists()}');
          input = await csvFile.readAsString();
          // debugPrint('Successfully read file data: ${input.length} characters');
        }

        // Check if the input is empty or just whitespace
        if (input.trim().isEmpty) {
          throw Exception('CSV file is empty or contains only whitespace');
        }
      } catch (e) {
        // debugPrint('Error reading CSV file: $e');
        throw Exception('Failed to read CSV file: $e');
      }

      // Debug: Print the first 100 characters of the CSV data
      // debugPrint(
      //   'CSV data preview: ${input.substring(0, input.length > 100 ? 100 : input.length)}...',
      // );

      // Check for line endings and adjust if needed
      String processedInput = input;
      if (!input.contains('\n') && input.contains('\r')) {
        // If there are no newlines but there are carriage returns, replace them
        // debugPrint('CSV file uses only CR line endings, converting to LF');
        processedInput = input.replaceAll('\r', '\n');
      } else if (input.contains('\r\n')) {
        // If CRLF line endings, normalize to just LF
        // debugPrint('CSV file uses CRLF line endings, converting to LF');
        processedInput = input.replaceAll('\r\n', '\n');
      }

      // Count lines to verify
      // int lineCount = '\n'.allMatches(processedInput).length + 1;
      // debugPrint('CSV file contains approximately $lineCount lines');

      // Use CsvToListConverter with explicit parameters to handle different CSV formats
      final List<List<dynamic>> csvData = const CsvToListConverter(
        fieldDelimiter: ',', // Use comma as delimiter
        eol: '\n', // Use newline as end of line
        shouldParseNumbers: false, // Don't parse numbers automatically
      ).convert(processedInput);

      // Debug: Print raw CSV data for inspection
      // debugPrint('Raw CSV data (first few rows):');
      // for (int i = 0; i < (csvData.length > 3 ? 3 : csvData.length); i++) {
        // debugPrint('Row $i: ${csvData[i]}');
      // }

      // Debug: Print the number of rows in the CSV data
      // debugPrint('CSV data rows: ${csvData.length}');

      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Skip header if needed
      List<List<dynamic>> dataRows;
      if (skipHeader && csvData.length > 1) {
        // Skip the first row (header)
        dataRows = csvData.sublist(1);
        // debugPrint('Skipping header row: ${csvData[0]}');
      } else {
        dataRows = csvData;
        // debugPrint('Not skipping header row');
      }

      // Debug: Print the actual data rows being processed
      // debugPrint(
      //   'Will process ${dataRows.length} data rows (skipHeader=$skipHeader)',
      // );

      // Debug: Print the number of data rows after skipping header
      // debugPrint('Data rows after skipping header: ${dataRows.length}');

      if (dataRows.isEmpty) {
        throw Exception('No data rows found in CSV file');
      }

      // Debug: Print the first row of data
      // if (dataRows.isNotEmpty) {
      //   // debugPrint('First data row: ${dataRows[0]}');
      // }

      // Get all categories to match by name (with timeout)
      final categoriesSnapshot = await _firestore
          .collection('categories')
          .get()
          .timeout(
            const Duration(seconds: 20),
            onTimeout:
                () =>
                    throw TimeoutException(
                      'Timeout getting categories from Firestore',
                    ),
          );

      if (categoriesSnapshot.docs.isEmpty) {
        throw Exception(
          'No categories found in database. Please add categories first.',
        );
      }

      // Get existing products to check for duplicates (with timeout)
      final productsSnapshot = await _firestore
          .collection('products')
          .get()
          .timeout(
            const Duration(seconds: 20),
            onTimeout:
                () =>
                    throw TimeoutException(
                      'Timeout getting products from Firestore',
                    ),
          );

      // Store existing products with their full data for comparison
      final Map<String, Map<String, dynamic>> existingProducts = {};
      final Map<String, String> existingProductIds = {};

      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        final name = (data['name'] as String).toLowerCase().trim();
        existingProducts[name] = data;
        existingProductIds[name] = doc.id;
      }

      // Create a mutable set to track products added in this import session
      final Set<String> addedProductNames = {};
      int updatedCount = 0;

      // debugPrint('Found ${existingProducts.length} existing products');
      // if (existingProducts.isNotEmpty) {
      //   debugPrint(
      //     'Existing product names sample: ${existingProducts.keys.take(5).join(", ")}',
      //   );
      // }

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

      // Debug: Print the categories found
      // debugPrint('Categories found: ${categoryNameToId.keys.join(', ')}');

      // Process each row
      // debugPrint('Starting to process ${dataRows.length} rows');
      for (var i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        final rowIndex =
            skipHeader ? i + 2 : i + 1; // For error reporting (1-based index)

        // debugPrint(
        //   'Processing row $rowIndex (index $i of ${dataRows.length}): ${row.join(', ').substring(0, row.join(', ').length > 50 ? 50 : row.join(', ').length)}...',
        // );

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
          // debugPrint(
          //   'Looking for category: "$categoryName" (lowercase: "${categoryName.toLowerCase()}")',
          // );
          String? categoryId = categoryNameToId[categoryName.toLowerCase()];

          // If category not found, create it
          if (categoryId == null) {
            // debugPrint('Category "$categoryName" not found, creating it');

            try {
              // Create the category
              final categoryData = {
                'name': categoryName,
                'imageUrl': '', // Default empty image URL
              };

              final docRef = await _firestore
                  .collection('categories')
                  .add(categoryData);
              categoryId = docRef.id;

              // Update our maps
              categoryNameToId[categoryName.toLowerCase()] = categoryId;
              categoryIdToName[categoryId] = categoryName;

              // debugPrint(
              //   'Created new category: "$categoryName" with ID: $categoryId',
              // );
            } catch (e) {
              warnings.add(
                'Row $rowIndex: Failed to create category "$categoryName" for product "$name": $e',
              );
              skippedCount++;
              continue;
            }
          } else {
            // debugPrint('Found category ID: $categoryId for "$categoryName"');
          }

          // Check for duplicate product names (either existing in DB or added in this import)
          final normalizedName = name.toLowerCase().trim();

          // Check if product already added in this import session
          if (addedProductNames.contains(normalizedName)) {
            warnings.add(
              'Row $rowIndex: Product "$name" was already added in this import session. Skipping to next product.',
            );
            // debugPrint(
            //   'Skipping duplicate product from same import: "$name" (normalized: "$normalizedName")',
            // );
            skippedCount++;
            continue; // Skip to the next product
          }

          // Check if product exists in database
          if (existingProducts.containsKey(normalizedName)) {
            // Get existing product data
            final existingProduct = existingProducts[normalizedName]!;
            final productId = existingProductIds[normalizedName]!;

            // Create new product data
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
            };

            // Check if any field has changed
            bool hasChanged = false;
            final List<String> changedFields = [];

            // Compare fields
            if (existingProduct['description'] != description) {
              hasChanged = true;
              changedFields.add('description');
            }

            if ((existingProduct['price'] as num).toDouble() != price) {
              hasChanged = true;
              changedFields.add('price');
            }

            // Compare discount price (handle null case)
            final existingDiscountPrice =
                existingProduct['discountPrice'] != null
                    ? (existingProduct['discountPrice'] as num).toDouble()
                    : null;
            if (existingDiscountPrice != discountPrice) {
              hasChanged = true;
              changedFields.add('discountPrice');
            }

            if (existingProduct['imageUrl'] != imageUrl) {
              hasChanged = true;
              changedFields.add('imageUrl');
            }

            if (existingProduct['categoryId'] != categoryId) {
              hasChanged = true;
              changedFields.add('categoryId');
            }

            if ((existingProduct['stock'] as num).toInt() != stock) {
              hasChanged = true;
              changedFields.add('stock');
            }

            if (existingProduct['unit'] != unit) {
              hasChanged = true;
              changedFields.add('unit');
            }

            if (existingProduct['isPopular'] != isPopular) {
              hasChanged = true;
              changedFields.add('isPopular');
            }

            if (existingProduct['isFeatured'] != isFeatured) {
              hasChanged = true;
              changedFields.add('isFeatured');
            }

            if (hasChanged) {
              // Update the product
              try {
                await _firestore
                    .collection('products')
                    .doc(productId)
                    .update(productData);

                // debugPrint(
                //   'Updated existing product: "$name" (ID: $productId). Changed fields: ${changedFields.join(", ")}',
                // );

                updatedCount++;
                warnings.add(
                  'Row $rowIndex: Product "$name" already exists and was updated. Changed fields: ${changedFields.join(", ")}',
                );
              } catch (e) {
                // debugPrint('Error updating product: $e');
                errors.add(
                  'Row $rowIndex: Failed to update product in Firestore: $e',
                );
                skippedCount++;
              }
            } else {
              // No changes detected
              // debugPrint(
              //   'Skipping unchanged product: "$name" (normalized: "$normalizedName")',
              // );
              warnings.add(
                'Row $rowIndex: Product "$name" already exists with identical data. Skipping.',
              );
              skippedCount++;
            }

            continue; // Skip to the next product
          }

          // Create product data
          // final productData = {
          //   'name': name,
          //   'description': description,
          //   'price': price,
          //   'discountPrice': discountPrice,
          //   'imageUrl': imageUrl,
          //   'categoryId': categoryId,
          //   'categoryName': categoryIdToName[categoryId] ?? categoryName,
          //   'stock': stock,
          //   'unit': unit,
          //   'isPopular': isPopular,
          //   'isFeatured': isFeatured,
          //   'createdAt': FieldValue.serverTimestamp(),
          // };

          // Add to Firestore
          // debugPrint('Adding product to Firestore: "$name"');
          try {
            // final docRef = await _firestore
            //     .collection('products')
            //     .add(productData);
            // debugPrint(
            //   'Successfully added product to Firestore with ID: ${docRef.id}',
            // );

            // Add to our set of added products to prevent duplicates in the same import
            addedProductNames.add(normalizedName);

            importedCount++;
            // debugPrint(
            //   'Successfully imported product: "$name" (total imported: $importedCount)',
            // );
          } catch (e) {
            // debugPrint('Error adding product to Firestore: $e');
            errors.add('Row $rowIndex: Failed to add product to Firestore: $e');
            skippedCount++;
            continue;
          }

          // Removed duplicate increment and debug print
        } catch (e) {
          errors.add('Row $rowIndex: Failed to process row: $e');
          skippedCount++;
          // debugPrint('Error processing row $rowIndex: $e');
        }

        // Debug: Print progress after each row
        // debugPrint(
        //   'Completed row $rowIndex. Progress: $importedCount imported, $skippedCount skipped',
        // );
      }

      return {
        'success': true,
        'importedCount': importedCount,
        'updatedCount': updatedCount,
        'skippedCount': skippedCount,
        'errors': errors,
        'warnings': warnings,
      };
    } catch (e) {
      // debugPrint('Error importing products from CSV: $e');
      return {
        'success': false,
        'importedCount': importedCount,
        'updatedCount': updatedCount,
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
    int updatedCount = 0;
    int skippedCount = 0;

    try {
      // Read the CSV data - either from file or from web data
      String input;
      try {
        if (kIsWeb && _webCsvData != null) {
          // Use the web data if available
          input = _webCsvData!;
          // debugPrint('Using web CSV data: ${input.length} characters');
        } else {
          // Read from file for non-web platforms
          // debugPrint('Reading CSV file from path: ${csvFile.path}');
          // debugPrint('File exists: ${await csvFile.exists()}');
          input = await csvFile.readAsString();
          // debugPrint('Successfully read file data: ${input.length} characters');
        }

        // Check if the input is empty or just whitespace
        if (input.trim().isEmpty) {
          throw Exception('CSV file is empty or contains only whitespace');
        }
      } catch (e) {
        // debugPrint('Error reading CSV file: $e');
        throw Exception('Failed to read CSV file: $e');
      }

      // Check for line endings and adjust if needed
      String processedInput = input;
      if (!input.contains('\n') && input.contains('\r')) {
        // If there are no newlines but there are carriage returns, replace them
        // debugPrint('CSV file uses only CR line endings, converting to LF');
        processedInput = input.replaceAll('\r', '\n');
      } else if (input.contains('\r\n')) {
        // If CRLF line endings, normalize to just LF
        // debugPrint('CSV file uses CRLF line endings, converting to LF');
        processedInput = input.replaceAll('\r\n', '\n');
      }

      // Count lines to verify
      // int lineCount = '\n'.allMatches(processedInput).length + 1;
      // debugPrint('CSV file contains approximately $lineCount lines');

      // Use CsvToListConverter with explicit parameters to handle different CSV formats
      final List<List<dynamic>> csvData = const CsvToListConverter(
        fieldDelimiter: ',', // Use comma as delimiter
        eol: '\n', // Use newline as end of line
        shouldParseNumbers: false, // Don't parse numbers automatically
      ).convert(processedInput);

      // Debug: Print raw CSV data for inspection
      // debugPrint('Raw CSV data (first few rows):');
      // for (int i = 0; i < (csvData.length > 3 ? 3 : csvData.length); i++) {
      //   debugPrint('Row $i: ${csvData[i]}');
      // }

      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Skip header if needed
      List<List<dynamic>> dataRows;
      if (skipHeader && csvData.length > 1) {
        // Skip the first row (header)
        dataRows = csvData.sublist(1);
        // debugPrint('Skipping header row: ${csvData[0]}');
      } else {
        dataRows = csvData;
        // debugPrint('Not skipping header row');
      }

      // Debug: Print the actual data rows being processed
      // debugPrint(
      //   'Will process ${dataRows.length} data rows (skipHeader=$skipHeader)',
      // );

      if (dataRows.isEmpty) {
        throw Exception('No data rows found in CSV file');
      }

      // Get all categories to match by name (with timeout)
      final categoriesSnapshot = await _firestore
          .collection('categories')
          .get()
          .timeout(
            const Duration(seconds: 20),
            onTimeout:
                () =>
                    throw TimeoutException(
                      'Timeout getting categories from Firestore',
                    ),
          );

      if (categoriesSnapshot.docs.isEmpty) {
        throw Exception(
          'No categories found in database. Please add categories first.',
        );
      }

      // Get existing products to check for duplicates (with timeout)
      final productsSnapshot = await _firestore
          .collection('products')
          .get()
          .timeout(
            const Duration(seconds: 20),
            onTimeout:
                () =>
                    throw TimeoutException(
                      'Timeout getting products from Firestore',
                    ),
          );

      // Store existing products with their full data for comparison
      final Map<String, Map<String, dynamic>> existingProducts = {};
      final Map<String, String> existingProductIds = {};

      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        final name = (data['name'] as String).toLowerCase().trim();
        existingProducts[name] = data;
        existingProductIds[name] = doc.id;
      }

      // Create a mutable set to track products added in this import session
      final Set<String> addedProductNames = {};

      // debugPrint('Found ${existingProducts.length} existing products');
      // if (existingProducts.isNotEmpty) {
      //   debugPrint(
      //     'Existing product names sample: ${existingProducts.keys.take(5).join(", ")}',
      //   );
      // }

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

      // Create maps for image files (case insensitive)
      final Map<String, File> imageFileMap = {}; // For non-web platforms
      final Map<String, String> imageKeyMap =
          {}; // For mapping filenames to keys

      if (kIsWeb) {
        // For web platform, use the web image files
        // debugPrint('Processing ${_webImageFiles.length} web image files');

        for (var entry in _webImageFiles.entries) {
          final fileName = entry.key.toLowerCase();

          // Also add the filename without extension for more flexible matching
          final fileNameWithoutExt =
              fileName.contains('.')
                  ? fileName.substring(0, fileName.lastIndexOf('.'))
                  : fileName;

          // Store the mapping from filename to key
          imageKeyMap[fileName] = fileName;
          if (fileNameWithoutExt != fileName) {
            imageKeyMap[fileNameWithoutExt] = fileName;
          }

          // debugPrint(
          //   'Added web image file: $fileName (also as: $fileNameWithoutExt)',
          // );
        }
      } else {
        // For other platforms, use the file objects
        // debugPrint('Processing ${imageFiles.length} image files');

        for (var file in imageFiles) {
          final fileName = path.basename(file.path).toLowerCase();
          imageFileMap[fileName] = file;

          // Also add the filename without extension for more flexible matching
          final fileNameWithoutExt =
              fileName.contains('.')
                  ? fileName.substring(0, fileName.lastIndexOf('.'))
                  : fileName;
          if (fileNameWithoutExt != fileName) {
            imageFileMap[fileNameWithoutExt] = file;
          }

          // debugPrint(
          //   'Added image file: $fileName (also as: $fileNameWithoutExt)',
          // );
        }
      }

      // Process each row
      // debugPrint('Starting to process ${dataRows.length} rows');
      for (var i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        final rowIndex =
            skipHeader ? i + 2 : i + 1; // For error reporting (1-based index)

        // debugPrint(
        //   'Processing row $rowIndex (index $i of ${dataRows.length}): ${row.join(', ').substring(0, row.join(', ').length > 50 ? 50 : row.join(', ').length)}...',
        // );

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

          // Normalize name for comparison
          final normalizedName = name.toLowerCase().trim();

          // Check if product already added in this import session
          if (addedProductNames.contains(normalizedName)) {
            warnings.add(
              'Row $rowIndex: Product "$name" was already added in this import session. Skipping to next product.',
            );
            // debugPrint(
            //   'Skipping duplicate product from same import: "$name" (normalized: "$normalizedName")',
            // );
            skippedCount++;
            continue; // Skip to the next product
          }

          // Check if product exists in database
          if (existingProducts.containsKey(normalizedName)) {
            // Process after parsing all fields
            // Will check for changes and update if needed
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
          // debugPrint(
          //   'Looking for category: "$categoryName" (lowercase: "${categoryName.toLowerCase()}")',
          // );
          String? categoryId = categoryNameToId[categoryName.toLowerCase()];

          // If category not found, create it
          if (categoryId == null) {
            // debugPrint('Category "$categoryName" not found, creating it');

            try {
              // Create the category
              final categoryData = {
                'name': categoryName,
                'imageUrl': '', // Default empty image URL
              };

              // Add a timeout to prevent hanging
              final docRef = await _firestore
                  .collection('categories')
                  .add(categoryData)
                  .timeout(const Duration(seconds: 15));
              categoryId = docRef.id;

              // Update our maps
              categoryNameToId[categoryName.toLowerCase()] = categoryId;
              categoryIdToName[categoryId] = categoryName;

              // debugPrint(
              //   'Created new category: "$categoryName" with ID: $categoryId',
              // );
            } catch (e) {
              warnings.add(
                'Row $rowIndex: Failed to create category "$categoryName" for product "$name": $e',
              );
              skippedCount++;
              continue;
            }
          } else {
            // debugPrint('Found category ID: $categoryId for "$categoryName"');
          }

          // Upload image if available
          String imageUrl = '';
          if (imageFileName.isNotEmpty) {
            // Check if it's a URL
            if (imageFileName.startsWith('http')) {
              imageUrl = imageFileName;
              // debugPrint('Using URL as image: $imageUrl');
            } else {
              // Normalize the image filename for matching
              final normalizedFileName = imageFileName.toLowerCase().trim();
              final fileNameWithoutExt =
                  normalizedFileName.contains('.')
                      ? normalizedFileName.substring(
                        0,
                        normalizedFileName.lastIndexOf('.'),
                      )
                      : normalizedFileName;

              // debugPrint(
              //   'Looking for image file: "$normalizedFileName" or "$fileNameWithoutExt"',
              // );

              if (kIsWeb) {
                // For web platform, use the web image files
                String? imageKey;

                // Try to find the image key (case insensitive)
                imageKey = imageKeyMap[normalizedFileName];

                // If not found, try without extension
                if (imageKey == null &&
                    normalizedFileName != fileNameWithoutExt) {
                  imageKey = imageKeyMap[fileNameWithoutExt];
                  if (imageKey != null) {
                    // debugPrint(
                    //   'Found web image by name without extension: $fileNameWithoutExt',
                    // );
                  }
                }

                if (imageKey != null && _webImageFiles.containsKey(imageKey)) {
                  try {
                    final imageBytes = _webImageFiles[imageKey]!;
                    // debugPrint(
                    //   'Uploading web image file: $imageKey (${imageBytes.length} bytes)',
                    // );

                    final fileName =
                        '${DateTime.now().millisecondsSinceEpoch}_$imageKey';
                    final storageRef = _storage.ref().child(
                      'products/$fileName',
                    );

                    // Upload the image bytes with timeout
                    try {
                      // Add a timeout to prevent hanging
                      await storageRef
                          .putData(
                            imageBytes,
                            SettableMetadata(
                              contentType: 'image/${imageKey.split('.').last}',
                            ),
                          )
                          .timeout(const Duration(seconds: 30));

                      imageUrl = await storageRef.getDownloadURL().timeout(
                        const Duration(seconds: 10),
                      );

                      // debugPrint('Successfully uploaded web image: $imageUrl');
                    } catch (timeoutError) {
                      // debugPrint('Timeout uploading image: $timeoutError');
                      warnings.add(
                        'Row $rowIndex: Timeout uploading image "$imageFileName" for product "$name". The upload took too long.',
                      );
                      // Continue with empty image URL
                      imageUrl = '';
                    }
                  } catch (e) {
                    // debugPrint('Failed to upload web image: $e');
                    warnings.add(
                      'Row $rowIndex: Failed to upload image "$imageFileName" for product "$name": $e',
                    );
                  }
                } else {
                  // debugPrint('Web image file not found: $normalizedFileName');
                  warnings.add(
                    'Row $rowIndex: Image file "$imageFileName" not found for product "$name". Available files: ${_webImageFiles.keys.take(5).join(", ")}...',
                  );
                }
              } else {
                // For other platforms, use the file objects
                File? imageFile = imageFileMap[normalizedFileName];

                // If not found, try without extension
                if (imageFile == null &&
                    normalizedFileName != fileNameWithoutExt) {
                  imageFile = imageFileMap[fileNameWithoutExt];
                  if (imageFile != null) {
                    // debugPrint(
                    //   'Found image file by name without extension: $fileNameWithoutExt',
                    // );
                  }
                }

                if (imageFile != null) {
                  try {
                    // debugPrint('Uploading image file: ${imageFile.path}');
                    final fileName =
                        '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
                    final storageRef = _storage.ref().child(
                      'products/$fileName',
                    );

                    // Upload the file with timeout
                    try {
                      await storageRef
                          .putFile(imageFile)
                          .timeout(const Duration(seconds: 30));

                      imageUrl = await storageRef.getDownloadURL().timeout(
                        const Duration(seconds: 10),
                      );

                      // debugPrint('Successfully uploaded image: $imageUrl');
                    } catch (timeoutError) {
                      // debugPrint('Timeout uploading image: $timeoutError');
                      warnings.add(
                        'Row $rowIndex: Timeout uploading image "$imageFileName" for product "$name". The upload took too long.',
                      );
                      // Continue with empty image URL
                      imageUrl = '';
                    }
                  } catch (e) {
                    // debugPrint('Failed to upload image: $e');
                    warnings.add(
                      'Row $rowIndex: Failed to upload image "$imageFileName" for product "$name": $e',
                    );
                  }
                } else {
                  // debugPrint('Image file not found: $normalizedFileName');
                  warnings.add(
                    'Row $rowIndex: Image file "$imageFileName" not found for product "$name". Available files: ${imageFileMap.keys.take(5).join(", ")}...',
                  );
                }
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

          // Check if we need to update an existing product
          if (existingProducts.containsKey(normalizedName)) {
            // Get existing product data
            final existingProduct = existingProducts[normalizedName]!;
            final productId = existingProductIds[normalizedName]!;

            // Check if any field has changed
            bool hasChanged = false;
            final List<String> changedFields = [];

            // Compare fields
            if (existingProduct['description'] != description) {
              hasChanged = true;
              changedFields.add('description');
            }

            if ((existingProduct['price'] as num).toDouble() != price) {
              hasChanged = true;
              changedFields.add('price');
            }

            // Compare discount price (handle null case)
            final existingDiscountPrice =
                existingProduct['discountPrice'] != null
                    ? (existingProduct['discountPrice'] as num).toDouble()
                    : null;
            if (existingDiscountPrice != discountPrice) {
              hasChanged = true;
              changedFields.add('discountPrice');
            }

            if (existingProduct['imageUrl'] != imageUrl) {
              hasChanged = true;
              changedFields.add('imageUrl');
            }

            if (existingProduct['categoryId'] != categoryId) {
              hasChanged = true;
              changedFields.add('categoryId');
            }

            if ((existingProduct['stock'] as num).toInt() != stock) {
              hasChanged = true;
              changedFields.add('stock');
            }

            if (existingProduct['unit'] != unit) {
              hasChanged = true;
              changedFields.add('unit');
            }

            if (existingProduct['isPopular'] != isPopular) {
              hasChanged = true;
              changedFields.add('isPopular');
            }

            if (existingProduct['isFeatured'] != isFeatured) {
              hasChanged = true;
              changedFields.add('isFeatured');
            }

            if (hasChanged) {
              // Update the product
              try {
                await _firestore
                    .collection('products')
                    .doc(productId)
                    .update(productData);

                // debugPrint(
                //   'Updated existing product: "$name" (ID: $productId). Changed fields: ${changedFields.join(", ")}',
                // );

                updatedCount++;
                warnings.add(
                  'Row $rowIndex: Product "$name" already exists and was updated. Changed fields: ${changedFields.join(", ")}',
                );
              } catch (e) {
                // debugPrint('Error updating product: $e');
                errors.add(
                  'Row $rowIndex: Failed to update product in Firestore: $e',
                );
                skippedCount++;
              }
            } else {
              // No changes detected
              // debugPrint(
              //   'Skipping unchanged product: "$name" (normalized: "$normalizedName")',
              // );
              warnings.add(
                'Row $rowIndex: Product "$name" already exists with identical data. Skipping.',
              );
              skippedCount++;
            }

            continue; // Skip to the next product
          }

          // Add to Firestore (only for new products)
          // debugPrint('Adding product to Firestore: "$name"');
          try {
            // Add a timeout to prevent hanging
            // final docRef = await _firestore
            //     .collection('products')
            //     .add(productData)
            //     .timeout(const Duration(seconds: 15));

            // debugPrint(
            //   'Successfully added product to Firestore with ID: ${docRef.id}',
            // );

            // Add to our set of added products to prevent duplicates in the same import
            addedProductNames.add(normalizedName);

            importedCount++;
            // debugPrint(
            //   'Successfully imported product: "$name" (total imported: $importedCount)',
            // );
          } catch (e) {
            String errorMessage = e.toString();
            if (e is TimeoutException) {
              errorMessage =
                  'Timeout adding product to Firestore. The operation took too long.';
            }

            // debugPrint('Error adding product to Firestore: $errorMessage');
            errors.add(
              'Row $rowIndex: Failed to add product to Firestore: $errorMessage',
            );
            skippedCount++;
            continue;
          }
        } catch (e) {
          errors.add('Row $rowIndex: Failed to process row: $e');
          skippedCount++;
          // debugPrint('Error processing row $rowIndex: $e');
        }

        // Debug: Print progress after each row
        // debugPrint(
        //   'Completed row $rowIndex. Progress: $importedCount imported, $skippedCount skipped',
        // );
      }

      return {
        'success': true,
        'importedCount': importedCount,
        'updatedCount': updatedCount,
        'skippedCount': skippedCount,
        'errors': errors,
        'warnings': warnings,
      };
    } catch (e) {
      // debugPrint('Error importing products with images: $e');
      return {
        'success': false,
        'importedCount': importedCount,
        'updatedCount': updatedCount,
        'skippedCount': skippedCount,
        'errors': [...errors, e.toString()],
        'warnings': warnings,
      };
    }
  }
}
