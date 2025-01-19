import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/order_model.dart';
import 'package:smart_kirana/providers/order_provider.dart';
import 'package:smart_kirana/utils/constants.dart';

class OrderTrackingScreen extends StatefulWidget {
  static const String routeName = '/order-tracking';
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Load order details when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderDetails();
      
      // Set up a timer to refresh order details every 30 seconds
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _loadOrderDetails();
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    if (mounted) {
      await Provider.of<OrderProvider>(context, listen: false)
          .getOrderById(widget.orderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
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
                    onPressed: _loadOrderDetails,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final order = orderProvider.selectedOrder;
          if (order == null) {
            return const Center(
              child: Text('Order not found'),
            );
          }

          return _buildOrderTracking(context, order);
        },
      ),
    );
  }

  Widget _buildOrderTracking(BuildContext context, OrderModel order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Status Card
          _buildStatusCard(order),
          const SizedBox(height: AppPadding.medium),

          // Map Placeholder (in a real app, this would be a Google Map)
          _buildMapPlaceholder(order),
          const SizedBox(height: AppPadding.medium),

          // Delivery Agent Info
          if (order.deliveryAgentName != null && order.deliveryAgentPhone != null)
            _buildDeliveryAgentCard(order),
          
          const SizedBox(height: AppPadding.medium),

          // Order Timeline
          _buildOrderTimeline(order),
        ],
      ),
    );
  }

  Widget _buildStatusCard(OrderModel order) {
    // Get status color
    Color statusColor;
    String statusText;
    
    switch (order.status) {
      case OrderStatus.delivered:
        statusColor = AppColors.success;
        statusText = 'Delivered';
        break;
      case OrderStatus.cancelled:
        statusColor = AppColors.error;
        statusText = 'Cancelled';
        break;
      case OrderStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Order Placed';
        break;
      case OrderStatus.processing:
        statusColor = AppColors.primary;
        statusText = 'Processing';
        break;
      case OrderStatus.shipped:
        statusColor = AppColors.secondary;
        statusText = 'Out for Delivery';
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(order.status),
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppPadding.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
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
            const SizedBox(height: AppPadding.medium),
            Text(
              'Order #${order.id.substring(0, 8)}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Placed on ${DateFormat('dd MMM yyyy, hh:mm a').format(order.orderDate)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder(OrderModel order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.map,
                size: 60,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppPadding.small),
              Text(
                'Map View',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: AppPadding.small),
              Text(
                'In a real app, this would be a Google Map\nshowing the delivery location and current position',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryAgentCard(OrderModel order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Agent', style: AppTextStyles.heading3),
            const SizedBox(height: AppPadding.medium),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: AppPadding.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.deliveryAgentName!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppPadding.small / 2),
                      Text(
                        order.deliveryAgentPhone!,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // In a real app, this would launch the phone app
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Calling delivery agent...'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.phone,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTimeline(OrderModel order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Timeline', style: AppTextStyles.heading3),
            const SizedBox(height: AppPadding.medium),
            _buildTimelineItem(
              'Order Placed',
              DateFormat('dd MMM yyyy, hh:mm a').format(order.orderDate),
              isCompleted: true,
              isFirst: true,
            ),
            _buildTimelineItem(
              'Order Processing',
              order.status.index >= OrderStatus.processing.index
                  ? 'Your order is being prepared'
                  : 'Pending',
              isCompleted: order.status.index >= OrderStatus.processing.index,
            ),
            _buildTimelineItem(
              'Out for Delivery',
              order.status.index >= OrderStatus.shipped.index
                  ? 'Your order is on the way'
                  : 'Pending',
              isCompleted: order.status.index >= OrderStatus.shipped.index,
            ),
            _buildTimelineItem(
              'Delivered',
              order.status == OrderStatus.delivered
                  ? 'Your order has been delivered'
                  : order.status == OrderStatus.cancelled
                      ? 'Order was cancelled'
                      : 'Pending',
              isCompleted: order.status == OrderStatus.delivered,
              isLast: true,
              isCancelled: order.status == OrderStatus.cancelled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle, {
    bool isCompleted = false,
    bool isFirst = false,
    bool isLast = false,
    bool isCancelled = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.primary
                    : isCancelled
                        ? AppColors.error
                        : Colors.grey.shade300,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.primary
                      : isCancelled
                          ? AppColors.error
                          : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    )
                  : isCancelled
                      ? const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 12,
                        )
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? AppColors.primary : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: AppPadding.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? AppColors.textPrimary
                      : isCancelled
                          ? AppColors.error
                          : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppPadding.small / 2),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (!isLast) const SizedBox(height: AppPadding.medium),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.access_time;
      case OrderStatus.processing:
        return Icons.inventory;
      case OrderStatus.shipped:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }
}
