import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/utils/csv_import_util.dart';

class ProductImportScreen extends StatefulWidget {
  static const String routeName = '/product-import';

  const ProductImportScreen({Key? key}) : super(key: key);

  @override
  State<ProductImportScreen> createState() => _ProductImportScreenState();
}

class _ProductImportScreenState extends State<ProductImportScreen> {
  File? _csvFile;
  List<File> _imageFiles = [];
  bool _isLoading = false;
  String _statusMessage = '';
  bool _importSuccess = false;
  int _importedCount = 0;
  int _skippedCount = 0;
  List<String> _errors = [];
  List<String> _warnings = [];
  bool _skipHeader = false;
  bool _showDetails = false;

  // Initialize CSVImportUtil
  CSVImportUtil? _csvImportUtil;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeImportUtil();
  }

  bool _isCSVImportUtilInitialized() {
    return _isInitialized && _csvImportUtil != null;
  }

  void _initializeImportUtil() {
    try {
      _csvImportUtil = CSVImportUtil();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      setState(() {
        _statusMessage = 'Error initializing import utility: $e';
        _importSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Products'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with steps
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bulk Import Products',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Follow these steps to import multiple products at once',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  _buildStepIndicator(),
                ],
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CSV File Selection
                  _buildSectionCard(
                    title: 'Step 1: Select CSV File',
                    icon: Icons.file_present,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your CSV file should include the following columns:',
                              style: TextStyle(fontSize: 14),
                            ),
                            if (kIsWeb)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withAlpha(30),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.blue.shade300,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.info,
                                      color: Colors.blue,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Web platform detected. CSV import is supported, but image uploads may be limited.',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildRequiredFieldsList(),
                        const SizedBox(height: 16),
                        _buildFileSelector(
                          label:
                              _csvFile != null
                                  ? path.basename(_csvFile!.path)
                                  : 'No CSV file selected',
                          icon: Icons.upload_file,
                          buttonText: 'Select CSV',
                          onPressed: _pickCSVFile,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text(
                            'Skip header row',
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Enable if your CSV has column headers',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          value: _skipHeader,
                          onChanged: (value) {
                            setState(() {
                              _skipHeader = value;
                            });
                          },
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Image Files Selection
                  _buildSectionCard(
                    title: 'Step 2: Add Product Images',
                    icon: Icons.image,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add image files for your products. The image filenames should match the "Image URL/filename" column in your CSV.',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        _buildFileSelector(
                          label:
                              _imageFiles.isNotEmpty
                                  ? '${_imageFiles.length} image${_imageFiles.length > 1 ? 's' : ''} selected'
                                  : 'No images selected',
                          icon: Icons.photo_library,
                          buttonText: 'Select Images',
                          onPressed: _pickImageFiles,
                        ),
                        if (_imageFiles.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Selected Images:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildImagePreviewGrid(),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Import Button
                  _buildSectionCard(
                    title: 'Step 3: Import Products',
                    icon: Icons.cloud_upload,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Click the button below to start importing products from your CSV file.',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed:
                                _csvFile != null && !_isLoading
                                    ? _importProducts
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text(
                                      'IMPORT PRODUCTS',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status Message
                  if (_statusMessage.isNotEmpty) _buildStatusCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle(1, 'Select CSV', true),
        _buildStepLine(true),
        _buildStepCircle(
          2,
          'Add Images',
          _imageFiles.isNotEmpty || _csvFile != null,
        ),
        _buildStepLine(_csvFile != null),
        _buildStepCircle(3, 'Import', _importSuccess),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white : Colors.white.withAlpha(100),
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: TextStyle(
                  color: isActive ? AppColors.primary : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withAlpha(180),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      color: isActive ? Colors.white : Colors.white.withAlpha(100),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredFieldsList() {
    final requiredFields = [
      {'name': 'Name', 'required': true},
      {'name': 'Description', 'required': true},
      {'name': 'Price', 'required': true},
      {'name': 'Discount Price', 'required': false},
      {'name': 'Image URL/filename', 'required': true},
      {'name': 'Category Name', 'required': true},
      {'name': 'Stock', 'required': true},
      {'name': 'Unit', 'required': false},
      {'name': 'Is Popular', 'required': false},
      {'name': 'Is Featured', 'required': false},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            requiredFields.map((field) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      field['required'] as bool
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color:
                          field['required'] as bool
                              ? AppColors.primary
                              : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      field['name'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            field['required'] as bool
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                    if (!(field['required'] as bool))
                      const Text(
                        ' (optional)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildFileSelector({
    required String label,
    required IconData icon,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _imageFiles.length,
      itemBuilder: (context, index) {
        final fileName = path.basename(_imageFiles[index].path);

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
              ),
              child:
                  kIsWeb
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image, color: Colors.grey),
                            const SizedBox(height: 4),
                            Text(
                              fileName,
                              style: const TextStyle(fontSize: 8),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      )
                      : Image.file(
                        _imageFiles[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  fileName,
                                  style: const TextStyle(fontSize: 8),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (kIsWeb) {
                      // For web platform, we need to re-select all images
                      // since we can't selectively remove one from CSVImportUtil
                      debugPrint(
                        'Removed image: ${path.basename(_imageFiles[index].path)}',
                      );

                      // Note: This is a limitation of the web platform
                      // In a production app, you would implement a more sophisticated
                      // solution to track and manage web image files
                    }

                    _imageFiles.removeAt(index);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: _importSuccess ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _importSuccess
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                  ),
                  child: Icon(
                    _importSuccess ? Icons.check : Icons.error,
                    color: _importSuccess ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _importSuccess ? 'Import Successful' : 'Import Failed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _importSuccess ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              _importSuccess
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_errors.isNotEmpty || _warnings.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      _showDetails
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: _importSuccess ? Colors.green : Colors.red,
                    ),
                    onPressed: () {
                      setState(() {
                        _showDetails = !_showDetails;
                      });
                    },
                  ),
              ],
            ),

            if (_showDetails) ...[
              const SizedBox(height: 16),
              const Divider(),

              // Errors
              if (_errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Errors (${_errors.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _errors.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(color: Colors.red),
                            ),
                            Expanded(
                              child: Text(
                                _errors[index],
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Warnings
              if (_warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Warnings (${_warnings.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _warnings.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(color: Colors.orange),
                            ),
                            Expanded(
                              child: Text(
                                _warnings[index],
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickCSVFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // Important: Get the file data for web platform
      );

      if (result != null) {
        if (kIsWeb) {
          // For web platform, we need to handle the CSV data differently
          // We'll store the bytes and filename to use later
          final bytes = result.files.single.bytes;
          final fileName = result.files.single.name;

          if (bytes == null) {
            setState(() {
              _statusMessage = 'Error: Could not read file data';
              _importSuccess = false;
            });
            return;
          }

          // Convert bytes to string for CSV processing
          final csvString = String.fromCharCodes(bytes);

          // Update the CSV import util to handle web files
          if (_csvImportUtil != null) {
            _csvImportUtil!.setWebCsvData(csvString, fileName);
          }

          setState(() {
            // We'll use a temporary file path for display purposes
            _csvFile = File(fileName);
            _statusMessage = '';
            _importSuccess = false;
          });
        } else {
          // For other platforms, use the path
          setState(() {
            _csvFile = File(result.files.single.path!);
            _statusMessage = '';
            _importSuccess = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting CSV file: $e';
        _importSuccess = false;
      });
    }
  }

  Future<void> _pickImageFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true, // Important: Get the file data for web platform
      );

      if (result != null && result.files.isNotEmpty) {
        if (kIsWeb) {
          // For web platform, we need to handle the image files differently
          // We'll store the bytes and filename to use later

          // Make sure CSVImportUtil is initialized
          if (!_isCSVImportUtilInitialized()) {
            _initializeImportUtil();
          }

          // Clear any existing web image files
          _csvImportUtil?.clearWebImageFiles();

          // Add each file to the CSVImportUtil
          for (var file in result.files) {
            if (file.name.isNotEmpty && file.bytes != null) {
              _csvImportUtil?.addWebImageFile(file.name, file.bytes!);
              debugPrint(
                'Added web image file: ${file.name} (${file.bytes!.length} bytes)',
              );
            }
          }

          setState(() {
            // For display purposes, create File objects with just the names
            _imageFiles =
                result.files
                    .where((file) => file.name.isNotEmpty)
                    .map((file) => File(file.name))
                    .toList();
            _statusMessage = '';
            _importSuccess = false;
          });

          debugPrint('Added ${result.files.length} web image files');
        } else {
          // For other platforms, use the path
          setState(() {
            _imageFiles =
                result.paths
                    .where((path) => path != null)
                    .map((path) => File(path!))
                    .toList();
            _statusMessage = '';
            _importSuccess = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting image files: $e';
        _importSuccess = false;
      });
      debugPrint('Error picking image files: $e');
    }
  }

  Future<void> _importProducts() async {
    if (_csvFile == null) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Importing products...';
      _importSuccess = false;
      _errors.clear();
      _warnings.clear();
    });

    try {
      // Make sure CSVImportUtil is initialized
      if (!_isCSVImportUtilInitialized()) {
        _initializeImportUtil();
      }

      // Check if CSVImportUtil is initialized
      if (_csvImportUtil == null) {
        throw Exception('Import utility is not initialized');
      }

      // Debug the import parameters
      debugPrint('Starting import with skipHeader: $_skipHeader');

      Map<String, dynamic> result;
      try {
        // Add a timeout for the entire import process
        if (_imageFiles.isNotEmpty) {
          debugPrint('Importing products with images');
          result = await _csvImportUtil!
              .importProductsWithImages(
                _csvFile!,
                _imageFiles,
                skipHeader: _skipHeader,
              )
              .timeout(
                const Duration(minutes: 5),
                onTimeout:
                    () =>
                        throw TimeoutException(
                          'The import process took too long and timed out. Please try again with fewer products or images.',
                        ),
              );
        } else {
          debugPrint('Importing products without images');
          result = await _csvImportUtil!
              .importProductsFromCSV(_csvFile!, skipHeader: _skipHeader)
              .timeout(
                const Duration(minutes: 5),
                onTimeout:
                    () =>
                        throw TimeoutException(
                          'The import process took too long and timed out. Please try again with fewer products.',
                        ),
              );
        }
      } catch (e) {
        if (e is TimeoutException) {
          debugPrint('Import timed out: $e');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _importSuccess = false;
              _statusMessage =
                  'Import timed out: The process took too long to complete.';
              _errors = [
                'The import process took too long and timed out. Please try again with fewer products or images.',
              ];
              _showDetails = true;
            });
          }
          return; // Exit the method early
        }
        rethrow;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _importSuccess = result['success'] as bool;
          _importedCount = result['importedCount'] as int;
          _skippedCount = result['skippedCount'] as int;
          _errors = List<String>.from(result['errors'] as List? ?? []);
          _warnings = List<String>.from(result['warnings'] as List? ?? []);

          if (_importSuccess) {
            if (_errors.isEmpty && _warnings.isEmpty) {
              _statusMessage =
                  'Successfully imported $_importedCount products.';
            } else {
              // Check if there are duplicate product warnings
              bool hasDuplicates = _warnings.any(
                (warning) => warning.contains('already exists in database'),
              );

              if (hasDuplicates && _skippedCount > 0) {
                _statusMessage =
                    'Imported $_importedCount products. Skipped $_skippedCount products (including duplicates). See details below.';
              } else {
                _statusMessage =
                    'Imported $_importedCount products with ${_warnings.length} warnings and ${_errors.length} errors.';
              }
              _showDetails = true;
            }
          } else {
            _statusMessage = 'Failed to import products. See details below.';
            _showDetails = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error in _importProducts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _importSuccess = false;
          _statusMessage = 'Error importing products: $e';
          _errors.add(e.toString());
          _showDetails = true;
        });
      }
    }
  }
}
