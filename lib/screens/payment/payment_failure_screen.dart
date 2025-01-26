import 'package:flutter/material.dart';
import 'package:smart_kirana/models/payment_model.dart' as payment_model;
import 'package:smart_kirana/screens/orders/order_detail_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/custom_button.dart';

class PaymentFailureScreen extends StatelessWidget {
  static const String routeName = '/payment-failure';
  final String orderId;
  final String paymentId;
  final double amount;
  final payment_model.PaymentMethod method;
  final String errorMessage;

  const PaymentFailureScreen({
    super.key,
    required this.orderId,
    required this.paymentId,
    required this.amount,
    required this.method,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.medium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Failure Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 80,
                ),
              ),
              const SizedBox(height: AppPadding.large),
              
              // Failure Message
              Text(
                'Payment Failed',
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppPadding.medium),
              Text(
                'Your payment could not be processed.',
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppPadding.small),
              Text(
                errorMessage,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
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
                    ],
                  ),
                ),
              ),
              const Spacer(),
              
              // Action Buttons
              CustomButton(
                text: 'Try Again',
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: AppPadding.medium),
              CustomButton(
                text: 'View Order Details',
                onPressed: () => _navigateToOrderDetails(context),
                type: ButtonType.outline,
              ),
              const SizedBox(height: AppPadding.medium),
              CustomButton(
                text: 'Continue Shopping',
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                type: ButtonType.text,
              ),
            ],
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

  String _getPaymentMethodName(payment_model.PaymentMethod method) {
    switch (method) {
      case payment_model.PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case payment_model.PaymentMethod.razorpay:
        return 'Razorpay';
      case payment_model.PaymentMethod.upi:
        return 'UPI';
      case payment_model.PaymentMethod.creditCard:
        return 'Credit/Debit Card';
      case payment_model.PaymentMethod.debitCard:
        return 'Debit Card';
      case payment_model.PaymentMethod.netBanking:
        return 'Net Banking';
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
