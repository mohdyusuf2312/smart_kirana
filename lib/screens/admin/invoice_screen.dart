import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:smart_kirana/models/order_model.dart';

class InvoiceScreen extends StatefulWidget {
  final OrderModel order;

  const InvoiceScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printInvoice,
            tooltip: 'Print Invoice',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _saveInvoice,
            tooltip: 'Save Invoice',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder<pw.Document>(
                future: _generateInvoice(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: Text('Failed to generate invoice'),
                    );
                  }

                  return PdfPreview(
                    build: (format) => snapshot.data!.save(),
                    allowPrinting: true,
                    allowSharing: true,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                  );
                },
              ),
    );
  }

  Future<pw.Document> _generateInvoice() async {
    final pdf = pw.Document();
    final order = widget.order;
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    // Load font
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Smart Kirana',
                        style: pw.TextStyle(font: fontBold, fontSize: 24),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Invoice #${order.id.substring(0, 8)}',
                        style: pw.TextStyle(font: font, fontSize: 14),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date: ${dateFormat.format(order.orderDate)}',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.Text(
                        'Time: ${timeFormat.format(order.orderDate)}',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Customer and Order Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Customer Information',
                        style: pw.TextStyle(font: fontBold, fontSize: 14),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Name: ${order.userName}',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Order ID: ${order.id}',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Payment Method: ${order.paymentMethod}',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 30),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Shipping Address',
                        style: pw.TextStyle(font: fontBold, fontSize: 14),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Container(
                        width: 230,
                        child: pw.Text(
                          '${order.deliveryAddress['label'] ?? ''}, '
                          '${order.deliveryAddress['addressLine'] ?? ''}, '
                          '${order.deliveryAddress['city'] ?? ''}, '
                          '${order.deliveryAddress['state'] ?? ''}-'
                          '${order.deliveryAddress['pincode'] ?? ''}\n'
                          '${order.deliveryAddress['phoneNumber'] ?? ''}',
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Order Items Table
              pw.Text(
                'Order Items',
                style: pw.TextStyle(font: fontBold, fontSize: 14),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Item',
                          style: pw.TextStyle(font: fontBold, fontSize: 12),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Quantity',
                          style: pw.TextStyle(font: fontBold, fontSize: 12),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Unit Price',
                          style: pw.TextStyle(font: fontBold, fontSize: 12),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Total',
                          style: pw.TextStyle(font: fontBold, fontSize: 12),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),

                  // Table Rows for Items
                  ...order.items.map(
                    (item) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            item.productName,
                            style: pw.TextStyle(font: font, fontSize: 12),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            item.quantity.toString(),
                            style: pw.TextStyle(font: font, fontSize: 12),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '₹${item.price.toStringAsFixed(2)}',
                            style: pw.TextStyle(font: font, fontSize: 12),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                            style: pw.TextStyle(font: font, fontSize: 12),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Order Summary
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 200,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Subtotal:',
                            style: pw.TextStyle(font: font, fontSize: 12),
                          ),
                          pw.Text(
                            '₹${order.subtotal.toStringAsFixed(2)}',
                            style: pw.TextStyle(font: font, fontSize: 12),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Delivery Fee:',
                            style: pw.TextStyle(font: font, fontSize: 12),
                          ),
                          pw.Text(
                            '₹${order.deliveryFee.toStringAsFixed(2)}',
                            style: pw.TextStyle(font: font, fontSize: 12),
                          ),
                        ],
                      ),
                      if (order.discount > 0) ...[
                        pw.SizedBox(height: 5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Discount:',
                              style: pw.TextStyle(font: font, fontSize: 12),
                            ),
                            pw.Text(
                              '-₹${order.discount.toStringAsFixed(2)}',
                              style: pw.TextStyle(font: font, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      pw.SizedBox(height: 5),
                      pw.Divider(),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Total:',
                            style: pw.TextStyle(font: fontBold, fontSize: 14),
                          ),
                          pw.Text(
                            '₹${order.totalAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(font: fontBold, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 40),

              // Footer
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Thank you for shopping with Smart Kirana!',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  'For any queries, please contact us at support@smartkirana.com',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> _printInvoice() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pdf = await _generateInvoice();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to print invoice: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveInvoice() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pdf = await _generateInvoice();
      final bytes = await pdf.save();
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/invoice_${widget.order.id.substring(0, 8)}.pdf',
      );

      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice saved to ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save invoice: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
