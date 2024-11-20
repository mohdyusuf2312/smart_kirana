import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/order_model.dart';
import 'package:smart_kirana/providers/order_provider.dart';
import 'package:smart_kirana/screens/orders/order_tracking_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/custom_button.dart';

class OrderDetailScreen extends StatefulWidget {
  static const String routeName = '/order-detail';
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load order details when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(
        context,
        listen: false,
      ).getOrderById(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orderProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppPadding.medium),
                  Text(
                    'Error loading order details',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: AppPadding.small),
                  Text(
                    orderProvider.error!,
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppPadding.medium),
                  ElevatedButton(
                    onPressed: () => orderProvider.getOrderById(widget.orderId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final order = orderProvider.selectedOrder;
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return _buildOrderDetails(context, order, orderProvider);
        },
      ),
    );
  }

  Widget _buildOrderDetails(
    BuildContext context,
    OrderModel order,
    OrderProvider orderProvider,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Status Card
          _buildStatusCard(order),
          const SizedBox(height: AppPadding.medium),

          // Order Items
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppPadding.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Items', style: AppTextStyles.heading3),
                  const SizedBox(height: AppPadding.medium),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return _buildOrderItemRow(item);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPadding.medium),

          // Order Summary
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppPadding.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Summary', style: AppTextStyles.heading3),
                  const SizedBox(height: AppPadding.medium),
                  _buildSummaryRow('Order ID', '#${order.id.substring(0, 8)}'),
                  _buildSummaryRow(
                    'Order Date',
                    dateFormat.format(order.orderDate),
                  ),
                  _buildSummaryRow('Payment Method', order.paymentMethod),
                  const Divider(height: 20),
                  _buildSummaryRow(
                    'Subtotal',
                    '₹${order.subtotal.toStringAsFixed(2)}',
                  ),
                  _buildSummaryRow(
                    'Delivery Fee',
                    '₹${order.deliveryFee.toStringAsFixed(2)}',
                  ),
                  if (order.discount > 0)
                    _buildSummaryRow(
                      'Discount',
                      '-₹${order.discount.toStringAsFixed(2)}',
                    ),
                  const Divider(height: 20),
                  _buildSummaryRow(
                    'Total',
                    '₹${order.totalAmount.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPadding.medium),

          // Delivery Address
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppPadding.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Address', style: AppTextStyles.heading3),
                  const SizedBox(height: AppPadding.medium),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary),
                      const SizedBox(width: AppPadding.small),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.deliveryAddress['addressLine'] ?? '',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppPadding.small),
                            Text(
                              '${order.deliveryAddress['city'] ?? ''}, ${order.deliveryAddress['state'] ?? ''} - ${order.deliveryAddress['pincode'] ?? ''}',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPadding.medium),

          // Action Buttons
          Column(
            children: [
              // Track Order button for all statuses except cancelled
              if (order.status != OrderStatus.cancelled)
                CustomButton(
                  text: 'Track Order',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      OrderTrackingScreen.routeName,
                      arguments: order.id,
                    );
                  },
                  icon: Icons.location_on,
                ),
              const SizedBox(height: AppPadding.medium),

              // Cancel Order button for all statuses except delivered and cancelled
              if (order.status != OrderStatus.delivered &&
                  order.status != OrderStatus.cancelled)
                CustomButton(
                  text: 'Cancel Order',
                  onPressed:
                      () => _showCancelDialog(context, order, orderProvider),
                  type: ButtonType.outline,
                  icon: Icons.cancel_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(OrderModel order) {
    // Get status color
    Color statusColor;
    IconData statusIcon;

    switch (order.status) {
      case OrderStatus.delivered:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case OrderStatus.cancelled:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      case OrderStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case OrderStatus.processing:
        statusColor = AppColors.primary;
        statusIcon = Icons.inventory;
        break;
      case OrderStatus.outForDelivery:
        statusColor = AppColors.secondary;
        statusIcon = Icons.local_shipping;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppPadding.medium),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          border: Border.all(color: statusColor, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 36),
            const SizedBox(width: AppPadding.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ${order.status.name.toUpperCase()}',
                    style: AppTextStyles.heading3.copyWith(color: statusColor),
                  ),
                  if (order.estimatedDeliveryTime != null &&
                      order.status != OrderStatus.cancelled &&
                      order.status != OrderStatus.delivered)
                    Text(
                      'Estimated delivery: ${DateFormat('dd MMM, hh:mm a').format(order.estimatedDeliveryTime!)}',
                      style: AppTextStyles.bodyMedium,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemRow(OrderItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.small),
          child: Image.network(
            item.productImage,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                color: AppColors.background,
                child: const Icon(Icons.image_not_supported),
              );
            },
          ),
        ),
        const SizedBox(width: AppPadding.medium),
        // Product Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppPadding.small / 2),
              Text(
                '₹${item.price.toStringAsFixed(2)} × ${item.quantity}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        // Item Total
        Text(
          '₹${item.totalPrice.toStringAsFixed(2)}',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.small),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                isTotal
                    ? AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                    : AppTextStyles.bodyMedium,
          ),
          Text(
            value,
            style:
                isTotal
                    ? AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    )
                    : AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    OrderModel order,
    OrderProvider orderProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Order'),
            content: const Text(
              'Are you sure you want to cancel this order? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No, Keep Order'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) => const AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: AppPadding.medium),
                              Text('Cancelling order...'),
                            ],
                          ),
                        ),
                  );

                  final success = await orderProvider.cancelOrder(order.id);

                  if (context.mounted) {
                    Navigator.pop(context); // Close loading dialog

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Order cancelled successfully'
                              : 'Failed to cancel order: ${orderProvider.error}',
                        ),
                        backgroundColor:
                            success ? AppColors.success : AppColors.error,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Yes, Cancel Order',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
  }
}
