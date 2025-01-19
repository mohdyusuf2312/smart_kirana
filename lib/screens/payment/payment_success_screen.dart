import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_kirana/models/payment_model.dart';
import 'package:smart_kirana/screens/orders/order_detail_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/custom_button.dart';

class PaymentSuccessScreen extends StatelessWidget {
  static const String routeName = '/payment-success';
  final String orderId;
  final String paymentId;
  final double amount;
  final PaymentMethod method;

  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
    required this.paymentId,
    required this.amount,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateToOrderDetails(context);
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.medium),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Success Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 80,
                  ),
                ),
                const SizedBox(height: AppPadding.large),
                
                // Success Message
                Text(
                  'Payment Successful!',
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppPadding.medium),
                Text(
                  'Your order has been placed successfully.',
                  style: AppTextStyles.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppPadding.large),
                
                // Payment Details
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppPadding.medium),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Order ID',
                          '#${orderId.substring(0, 8)}',
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          'Amount',
                          '₹${amount.toStringAsFixed(2)}',
                          valueStyle: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          'Payment Method',
                          _getPaymentMethodName(method),
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          'Date & Time',
                          DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
                        ),
                        if (method != PaymentMethod.cashOnDelivery) ...[
                          const Divider(height: 20),
                          _buildDetailRow(
                            'Transaction ID',
                            'txn_${paymentId.substring(0, 8)}',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                
                // Action Buttons
                CustomButton(
                  text: 'View Order Details',
                  onPressed: () => _navigateToOrderDetails(context),
                ),
                const SizedBox(height: AppPadding.medium),
                CustomButton(
                  text: 'Continue Shopping',
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  buttonType: ButtonType.outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: valueStyle ?? AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.razorpay:
        return 'Razorpay';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.creditCard:
        return 'Credit/Debit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.netBanking:
        return 'Net Banking';
      default:
        return 'Unknown';
    }
  }

  void _navigateToOrderDetails(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      OrderDetailScreen.routeName,
      (route) => route.isFirst,
      arguments: orderId,
    );
  }
}
