import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/order_model.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/screens/admin/invoice_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/admin/admin_drawer.dart';

class OrderManagementScreen extends StatefulWidget {
  static const String routeName = '/admin-orders';
  final Map<String, dynamic>? arguments;

  const OrderManagementScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String? _selectedOrderId;
  final List<String> _statusOptions = [
    'All',
    'pending',
    'processing',
    'outForDelivery',
    'delivered',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();

    // Check if we have arguments for filtering
    if (widget.arguments != null) {
      if (widget.arguments!.containsKey('filter')) {
        // Make sure the filter value matches one of our status options
        final filterValue = widget.arguments!['filter'];
        // Find the matching status option (case-insensitive)
        final matchingStatus = _statusOptions.firstWhere(
          (status) => status.toLowerCase() == filterValue.toLowerCase(),
          orElse: () => 'All',
        );
        _selectedStatus = matchingStatus;
      }
      if (widget.arguments!.containsKey('orderId')) {
        _selectedOrderId = widget.arguments!['orderId'];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Check if user is admin
    if (authProvider.user?.role != 'ADMIN') {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Unauthorized Access', style: AppTextStyles.heading1),
              const SizedBox(height: AppPadding.medium),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Order Management')),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child:
                _selectedOrderId != null
                    ? _buildOrderDetails()
                    : _buildOrderList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(AppPadding.medium),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search by order ID or customer name...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: AppPadding.medium),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _statusOptions.length,
              itemBuilder: (context, index) {
                final status = _statusOptions[index];
                final isSelected = status == _selectedStatus;

                return Padding(
                  padding: const EdgeInsets.only(right: AppPadding.small),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedStatus = status;
                        });
                      }
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primary.withAlpha(
                      51,
                    ), // 0.2 * 255 ≈ 51
                    labelStyle: TextStyle(
                      color:
                          isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('orders')
              .orderBy('orderDate', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No orders found'));
        }

        // Filter orders based on search query and status
        var filteredDocs = snapshot.data!.docs;

        if (_searchQuery.isNotEmpty) {
          filteredDocs =
              filteredDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final orderId = doc.id;
                final userName = data['userName'] as String? ?? '';

                return orderId.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    userName.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();
        }

        if (_selectedStatus != 'All') {
          filteredDocs =
              filteredDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] as String? ?? '';

                // Case-insensitive comparison to handle different case formats
                return status.toLowerCase() == _selectedStatus.toLowerCase();
              }).toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppPadding.medium),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final order = OrderModel.fromMap(data, doc.id);

            return Card(
              margin: const EdgeInsets.only(bottom: AppPadding.medium),
              child: ListTile(
                title: Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer: ${order.userName}'),
                    Text(
                      'Date: ${DateFormat('MMM d, yyyy').format(order.orderDate)}',
                    ),
                    Row(
                      children: [
                        Text('Status: '),
                        _buildStatusChip(order.status.name),
                      ],
                    ),
                  ],
                ),
                trailing: Text(
                  '₹${order.totalAmount.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedOrderId = order.id;
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrderDetails() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('orders').doc(_selectedOrderId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Order not found'),
                const SizedBox(height: AppPadding.medium),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedOrderId = null;
                    });
                  },
                  child: const Text('Back to Orders'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final order = OrderModel.fromMap(data, snapshot.data!.id);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppPadding.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedOrderId = null;
                      });
                    },
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.receipt_long),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InvoiceScreen(order: order),
                            ),
                          );
                        },
                        tooltip: 'Generate Invoice',
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          // Refresh is automatic with StreamBuilder
                        },
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppPadding.small),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppPadding.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order.id.substring(0, 8)}',
                            style: AppTextStyles.heading2,
                          ),
                          _buildStatusDropdown(order),
                        ],
                      ),
                      const SizedBox(height: AppPadding.medium),
                      Text(
                        'Order Date: ${DateFormat('MMM d, yyyy hh:mm a').format(order.orderDate)}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppPadding.small),
                      Text(
                        'Customer: ${order.userName}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppPadding.small),
                      Text(
                        'Payment Method: ${order.paymentMethod}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      if (order.deliveryNotes != null &&
                          order.deliveryNotes!.isNotEmpty) ...[
                        const SizedBox(height: AppPadding.small),
                        Text(
                          'Delivery Notes: ${order.deliveryNotes}',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppPadding.medium),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppPadding.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Address',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: AppPadding.small),
                      Text(
                        '${order.deliveryAddress['label'] ?? ''}, '
                        '${order.deliveryAddress['addressLine'] ?? ''}, '
                        '${order.deliveryAddress['city'] ?? ''}, '
                        '${order.deliveryAddress['state'] ?? ''}-'
                        '${order.deliveryAddress['pincode'] ?? ''}\n'
                        '${order.deliveryAddress['phoneNumber'] ?? ''}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppPadding.medium),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppPadding.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Items', style: AppTextStyles.heading3),
                      const SizedBox(height: AppPadding.medium),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: order.items.length,
                        itemBuilder: (context, index) {
                          final item = order.items[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppPadding.small,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    item.productName,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '${item.quantity} x',
                                    style: AppTextStyles.bodyMedium,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '₹${item.price.toStringAsFixed(2)}',
                                    style: AppTextStyles.bodyMedium,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      _buildOrderSummary(order),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'PENDING':
        color = Colors.orange;
        break;
      case 'PROCESSING':
        color = Colors.blue;
        break;
      case 'OUT FOR DELIVERY':
        color = Colors.purple;
        break;
      case 'DELIVERED':
        color = AppColors.success;
        break;
      case 'CANCELLED':
        color = AppColors.error;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(status, style: TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildStatusDropdown(OrderModel order) {
    return DropdownButton<String>(
      value: order.status.name,
      items:
          [
            'pending',
            'processing',
            'outForDelivery',
            'delivered',
            'cancelled',
          ].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged: (newValue) async {
        if (newValue != null && newValue != order.status.name) {
          try {
            await _firestore.collection('orders').doc(order.id).update({
              'status': newValue,
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Order status updated to $newValue')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update order status: $e')),
              );
            }
          }
        }
      },
      underline: Container(height: 2, color: AppColors.primary),
    );
  }

  Widget _buildOrderSummary(OrderModel order) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtotal'),
            Text('₹${order.subtotal.toStringAsFixed(2)}'),
          ],
        ),
        const SizedBox(height: AppPadding.small),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Delivery Fee'),
            Text('₹${order.deliveryFee.toStringAsFixed(2)}'),
          ],
        ),
        if (order.discount > 0) ...[
          const SizedBox(height: AppPadding.small),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Discount'),
              Text('-₹${order.discount.toStringAsFixed(2)}'),
            ],
          ),
        ],
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '₹${order.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
