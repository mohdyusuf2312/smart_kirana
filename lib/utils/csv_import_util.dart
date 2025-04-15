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

  // Web platform specific data
  String? _webCsvData;
  String? _webCsvFileName;

  /// Set CSV data for web platform
  void setWebCsvData(String csvData, String fileName) {
    _webCsvData = csvData;
    _webCsvFileName = fileName;
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
    int skippedCount = 0;

    try {
      // Read the CSV data - either from file or from web data
      String input;
      try {
        if (kIsWeb && _webCsvData != null) {
          // Use the web data if available
          input = _webCsvData!;
          debugPrint('Using web CSV data: ${input.length} characters');
        } else {
          // Read from file for non-web platforms
          debugPrint('Reading CSV file from path: ${csvFile.path}');
          debugPrint('File exists: ${await csvFile.exists()}');
          input = await csvFile.readAsString();
          debugPrint('Successfully read file data: ${input.length} characters');
        }

        // Check if the input is empty or just whitespace
        if (input.trim().isEmpty) {
          throw Exception('CSV file is empty or contains only whitespace');
        }
      } catch (e) {
        debugPrint('Error reading CSV file: $e');
        throw Exception('Failed to read CSV file: $e');
      }

      // Debug: Print the first 100 characters of the CSV data
      debugPrint(
        'CSV data preview: ${input.substring(0, input.length > 100 ? 100 : input.length)}...',
      );

      // Check for line endings and adjust if needed
      String processedInput = input;
      if (!input.contains('\n') && input.contains('\r')) {
        // If there are no newlines but there are carriage returns, replace them
        debugPrint('CSV file uses only CR line endings, converting to LF');
        processedInput = input.replaceAll('\r', '\n');
      } else if (input.contains('\r\n')) {
        // If CRLF line endings, normalize to just LF
        debugPrint('CSV file uses CRLF line endings, converting to LF');
        processedInput = input.replaceAll('\r\n', '\n');
      }

      // Count lines to verify
      int lineCount = '\n'.allMatches(processedInput).length + 1;
      debugPrint('CSV file contains approximately $lineCount lines');

      // Use CsvToListConverter with explicit parameters to handle different CSV formats
      final List<List<dynamic>> csvData = const CsvToListConverter(
        fieldDelimiter: ',', // Use comma as delimiter
        eol: '\n', // Use newline as end of line
        shouldParseNumbers: false, // Don't parse numbers automatically
      ).convert(processedInput);

      // Debug: Print raw CSV data for inspection
      debugPrint('Raw CSV data (first few rows):');
      for (int i = 0; i < (csvData.length > 3 ? 3 : csvData.length); i++) {
        debugPrint('Row $i: ${csvData[i]}');
      }

      // Debug: Print the number of rows in the CSV data
      debugPrint('CSV data rows: ${csvData.length}');

      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Skip header if needed
      List<List<dynamic>> dataRows;
      if (skipHeader && csvData.length > 1) {
        // Skip the first row (header)
        dataRows = csvData.sublist(1);
        debugPrint('Skipping header row: ${csvData[0]}');
      } else {
        dataRows = csvData;
        debugPrint('Not skipping header row');
      }

      // Debug: Print the actual data rows being processed
      debugPrint(
        'Will process ${dataRows.length} data rows (skipHeader=$skipHeader)',
      );

      // Debug: Print the number of data rows after skipping header
      debugPrint('Data rows after skipping header: ${dataRows.length}');

      if (dataRows.isEmpty) {
        throw Exception('No data rows found in CSV file');
      }

      // Debug: Print the first row of data
      if (dataRows.isNotEmpty) {
        debugPrint('First data row: ${dataRows[0]}');
      }

      // Get all categories to match by name
      final categoriesSnapshot =
          await _firestore.collection('categories').get();

      if (categoriesSnapshot.docs.isEmpty) {
        throw Exception(
          'No categories found in database. Please add categories first.',
        );
      }

      // Get existing products to check for duplicates
      final productsSnapshot = await _firestore.collection('products').get();
      final existingProductNames =
          productsSnapshot.docs
              .map((doc) => (doc.data()['name'] as String).toLowerCase().trim())
              .toSet();

      // Create a mutable set to track products added in this import session
      final Set<String> addedProductNames = {};

      debugPrint('Found ${existingProductNames.length} existing products');
      if (existingProductNames.isNotEmpty) {
        debugPrint(
          'Existing product names sample: ${existingProductNames.take(5).join(", ")}',
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

      // Debug: Print the categories found
      debugPrint('Categories found: ${categoryNameToId.keys.join(', ')}');

      // Process each row
      debugPrint('Starting to process ${dataRows.length} rows');
      for (var i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        final rowIndex =
            skipHeader ? i + 2 : i + 1; // For error reporting (1-based index)

        debugPrint(
          'Processing row $rowIndex (index $i of ${dataRows.length}): ${row.join(', ').substring(0, row.join(', ').length > 50 ? 50 : row.join(', ').length)}...',
        );

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

          // Check for duplicate product names (either existing in DB or added in this import)
          final normalizedName = name.toLowerCase().trim();
          if (existingProductNames.contains(normalizedName) ||
              addedProductNames.contains(normalizedName)) {
            warnings.add(
              'Row $rowIndex: Product "$name" already exists. Skipping row.',
            );
            debugPrint(
              'Skipping duplicate product: "$name" (normalized: "$normalizedName")',
            );
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
          debugPrint(
            'Looking for category: "$categoryName" (lowercase: "${categoryName.toLowerCase()}")',
          );
          String? categoryId = categoryNameToId[categoryName.toLowerCase()];

          // If category not found, create it
          if (categoryId == null) {
            debugPrint('Category "$categoryName" not found, creating it');

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

              debugPrint(
                'Created new category: "$categoryName" with ID: $categoryId',
              );
            } catch (e) {
              warnings.add(
                'Row $rowIndex: Failed to create category "$categoryName" for product "$name": $e',
              );
              skippedCount++;
              continue;
            }
          } else {
            debugPrint('Found category ID: $categoryId for "$categoryName"');
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
          debugPrint('Adding product to Firestore: "$name"');
          try {
            final docRef = await _firestore
                .collection('products')
                .add(productData);
            debugPrint(
              'Successfully added product to Firestore with ID: ${docRef.id}',
            );

            // Add to our set of added products to prevent duplicates in the same import
            addedProductNames.add(normalizedName);

            importedCount++;
            debugPrint(
              'Successfully imported product: "$name" (total imported: $importedCount)',
            );
          } catch (e) {
            debugPrint('Error adding product to Firestore: $e');
            errors.add('Row $rowIndex: Failed to add product to Firestore: $e');
            skippedCount++;
            continue;
          }

          // Removed duplicate increment and debug print
        } catch (e) {
          errors.add('Row $rowIndex: Failed to process row: $e');
          skippedCount++;
          debugPrint('Error processing row $rowIndex: $e');
        }

        // Debug: Print progress after each row
        debugPrint(
          'Completed row $rowIndex. Progress: $importedCount imported, $skippedCount skipped',
        );
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
      // Read the CSV data - either from file or from web data
      String input;
      try {
        if (kIsWeb && _webCsvData != null) {
          // Use the web data if available
          input = _webCsvData!;
          debugPrint('Using web CSV data: ${input.length} characters');
        } else {
          // Read from file for non-web platforms
          debugPrint('Reading CSV file from path: ${csvFile.path}');
          debugPrint('File exists: ${await csvFile.exists()}');
          input = await csvFile.readAsString();
          debugPrint('Successfully read file data: ${input.length} characters');
        }

        // Check if the input is empty or just whitespace
        if (input.trim().isEmpty) {
          throw Exception('CSV file is empty or contains only whitespace');
        }
      } catch (e) {
        debugPrint('Error reading CSV file: $e');
        throw Exception('Failed to read CSV file: $e');
      }

      // Check for line endings and adjust if needed
      String processedInput = input;
      if (!input.contains('\n') && input.contains('\r')) {
        // If there are no newlines but there are carriage returns, replace them
        debugPrint('CSV file uses only CR line endings, converting to LF');
        processedInput = input.replaceAll('\r', '\n');
      } else if (input.contains('\r\n')) {
        // If CRLF line endings, normalize to just LF
        debugPrint('CSV file uses CRLF line endings, converting to LF');
        processedInput = input.replaceAll('\r\n', '\n');
      }

      // Count lines to verify
      int lineCount = '\n'.allMatches(processedInput).length + 1;
      debugPrint('CSV file contains approximately $lineCount lines');

      // Use CsvToListConverter with explicit parameters to handle different CSV formats
      final List<List<dynamic>> csvData = const CsvToListConverter(
        fieldDelimiter: ',', // Use comma as delimiter
        eol: '\n', // Use newline as end of line
        shouldParseNumbers: false, // Don't parse numbers automatically
      ).convert(processedInput);

      // Debug: Print raw CSV data for inspection
      debugPrint('Raw CSV data (first few rows):');
      for (int i = 0; i < (csvData.length > 3 ? 3 : csvData.length); i++) {
        debugPrint('Row $i: ${csvData[i]}');
      }

      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Skip header if needed
      List<List<dynamic>> dataRows;
      if (skipHeader && csvData.length > 1) {
        // Skip the first row (header)
        dataRows = csvData.sublist(1);
        debugPrint('Skipping header row: ${csvData[0]}');
      } else {
        dataRows = csvData;
        debugPrint('Not skipping header row');
      }

      // Debug: Print the actual data rows being processed
      debugPrint(
        'Will process ${dataRows.length} data rows (skipHeader=$skipHeader)',
      );

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

      // Get existing products to check for duplicates
      final productsSnapshot = await _firestore.collection('products').get();
      final existingProductNames =
          productsSnapshot.docs
              .map((doc) => (doc.data()['name'] as String).toLowerCase().trim())
              .toSet();

      // Create a mutable set to track products added in this import session
      final Set<String> addedProductNames = {};

      debugPrint('Found ${existingProductNames.length} existing products');
      if (existingProductNames.isNotEmpty) {
        debugPrint(
          'Existing product names sample: ${existingProductNames.take(5).join(", ")}',
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
      debugPrint('Starting to process ${dataRows.length} rows');
      for (var i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        final rowIndex =
            skipHeader ? i + 2 : i + 1; // For error reporting (1-based index)

        debugPrint(
          'Processing row $rowIndex (index $i of ${dataRows.length}): ${row.join(', ').substring(0, row.join(', ').length > 50 ? 50 : row.join(', ').length)}...',
        );

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

          // Check for duplicate product names (either existing in DB or added in this import)
          final normalizedName = name.toLowerCase().trim();
          if (existingProductNames.contains(normalizedName) ||
              addedProductNames.contains(normalizedName)) {
            warnings.add(
              'Row $rowIndex: Product "$name" already exists. Skipping row.',
            );
            debugPrint(
              'Skipping duplicate product: "$name" (normalized: "$normalizedName")',
            );
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
          debugPrint(
            'Looking for category: "$categoryName" (lowercase: "${categoryName.toLowerCase()}")',
          );
          String? categoryId = categoryNameToId[categoryName.toLowerCase()];

          // If category not found, create it
          if (categoryId == null) {
            debugPrint('Category "$categoryName" not found, creating it');

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

              debugPrint(
                'Created new category: "$categoryName" with ID: $categoryId',
              );
            } catch (e) {
              warnings.add(
                'Row $rowIndex: Failed to create category "$categoryName" for product "$name": $e',
              );
              skippedCount++;
              continue;
            }
          } else {
            debugPrint('Found category ID: $categoryId for "$categoryName"');
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
          debugPrint('Adding product to Firestore: "$name"');
          try {
            final docRef = await _firestore
                .collection('products')
                .add(productData);
            debugPrint(
              'Successfully added product to Firestore with ID: ${docRef.id}',
            );

            // Add to our set of added products to prevent duplicates in the same import
            addedProductNames.add(normalizedName);

            importedCount++;
            debugPrint(
              'Successfully imported product: "$name" (total imported: $importedCount)',
            );
          } catch (e) {
            debugPrint('Error adding product to Firestore: $e');
            errors.add('Row $rowIndex: Failed to add product to Firestore: $e');
            skippedCount++;
            continue;
          }
        } catch (e) {
          errors.add('Row $rowIndex: Failed to process row: $e');
          skippedCount++;
          debugPrint('Error processing row $rowIndex: $e');
        }

        // Debug: Print progress after each row
        debugPrint(
          'Completed row $rowIndex. Progress: $importedCount imported, $skippedCount skipped',
        );
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
