# Product Import Instructions

This document provides instructions on how to import products into Smart Kirana using the CSV import functionality.

## CSV File Format

The CSV file should have the following columns:

1. **Name** (required): The name of the product
2. **Description** (required): A description of the product
3. **Price** (required): The regular price of the product (numeric)
4. **DiscountPrice** (optional): The discounted price of the product (numeric)
5. **ImageUrl/filename** (required): Either a URL to an image or the filename of an image you'll upload
6. **CategoryName** (required): The name of the category (will be created if it doesn't exist)
7. **Stock** (required): The quantity in stock (numeric)
8. **Unit** (optional): The unit of measurement (e.g., kg, g, L)
9. **IsPopular** (optional): Whether the product should be marked as popular (yes/no, true/false, 1/0)
10. **IsFeatured** (optional): Whether the product should be featured (yes/no, true/false, 1/0)

## Sample CSV

A sample CSV file (`sample_products.csv`) is provided in the project. You can use this as a template for your own imports.

## Importing Products

1. Go to the Product Management screen
2. Click the "Import" button (upload icon)
3. Follow the steps in the import screen:

### Step 1: Select CSV File
- Click "Select CSV" to choose your CSV file
- Enable "Skip header row" if your CSV has column headers (recommended)

### Step 2: Add Product Images (Optional)
- Click "Select Images" to choose image files for your products
- The image filenames should match the "ImageUrl/filename" column in your CSV
- You can select multiple images at once

### Step 3: Import Products
- Click "IMPORT PRODUCTS" to start the import process
- The system will process each row in your CSV file
- You'll see a summary of imported and skipped products
- Any errors or warnings will be displayed

## Image Matching

When importing products with images:

1. If the "ImageUrl/filename" column contains a URL (starts with "http"), that URL will be used directly
2. Otherwise, the system will look for a matching image file among the files you selected
3. The matching is case-insensitive and will work with or without file extensions
4. For example, if your CSV has "product1.jpg", it will match files named "product1.jpg", "Product1.JPG", or even just "product1"

## Handling Duplicates

- Products with names that already exist in the database will be skipped
- The system checks for duplicates case-insensitively
- The import process will continue with the next product

## Troubleshooting

If you encounter issues during import:

1. Check the error and warning messages displayed after import
2. Ensure your CSV file follows the required format
3. For image issues, make sure the filenames in your CSV match the actual image files
4. If a category doesn't exist, it will be created automatically

For more help, contact the system administrator.
