import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/cart_item_model.dart';
import 'package:smart_kirana/models/order_model.dart' as order_model;
import 'package:smart_kirana/models/payment_model.dart' as payment_model;
import 'package:smart_kirana/models/user_model.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/providers/cart_provider.dart';
import 'package:smart_kirana/providers/order_provider.dart';
import 'package:smart_kirana/providers/payment_provider.dart';
import 'package:smart_kirana/screens/payment/payment_failure_screen.dart';
import 'package:smart_kirana/screens/payment/payment_success_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/custom_button.dart';

class PaymentScreen extends StatefulWidget {
  static const String routeName = '/payment';
  final String? orderId; // Optional for new flow
  final double amount;
  final List<CartItemModel>? cartItems; // For new flow
  final double? subtotal; // For new flow
  final double? deliveryFee; // For new flow
  final UserAddress? deliveryAddress; // For new flow

  const PaymentScreen({
    super.key,
    this.orderId,
    required this.amount,
    this.cartItems,
    this.subtotal,
    this.deliveryFee,
    this.deliveryAddress,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedPaymentMethod = 0;
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'Cash on Delivery',
      'icon': Icons.money,
      'method': payment_model.PaymentMethod.cashOnDelivery,
      'description': 'Pay when your order is delivered',
    },
    {
      'name': 'Credit/Debit Card',
      'icon': Icons.credit_card,
      'method': payment_model.PaymentMethod.creditCard,
      'description': 'Pay securely with your card',
    },
    {
      'name': 'UPI',
      'icon': Icons.account_balance,
      'method': payment_model.PaymentMethod.upi,
      'description': 'Pay using UPI apps like Google Pay, PhonePe, etc.',
    },
    {
      'name': 'Net Banking',
      'icon': Icons.account_balance_wallet,
      'method': payment_model.PaymentMethod.netBanking,
      'description': 'Pay using your bank account',
    },
  ];

  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Amount Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order Total', style: AppTextStyles.heading3),
                        Text(
                          '₹${widget.amount.toStringAsFixed(2)}',
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppPadding.small),
                    const Divider(),
                    const SizedBox(height: AppPadding.small),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16),
                        const SizedBox(width: AppPadding.small),
                        Expanded(
                          child: Text(
                            'Please select a payment method to complete your order',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppPadding.medium),

            // Payment Methods
            Text('Payment Methods', style: AppTextStyles.heading3),
            const SizedBox(height: AppPadding.small),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _paymentMethods.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final method = _paymentMethods[index];
                  return RadioListTile(
                    title: Row(
                      children: [
                        Icon(method['icon'], color: AppColors.primary),
                        const SizedBox(width: AppPadding.small),
                        Text(method['name']),
                      ],
                    ),
                    subtitle: Text(
                      method['description'],
                      style: AppTextStyles.bodySmall,
                    ),
                    value: index,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value as int;
                      });
                    },
                    activeColor: AppColors.primary,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.medium,
                      vertical: AppPadding.small,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppPadding.large),

            // Payment Button
            CustomButton(
              text: 'Pay Now',
              onPressed: () => _processPayment(context),
              isLoading: _isProcessing,
              enabled: !_isProcessing,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(BuildContext contextArg) async {
    // Store context-related objects before the async gap
    final navigator = Navigator.of(contextArg);
    final scaffoldMessenger = ScaffoldMessenger.of(contextArg);
    final selectedMethod =
        _paymentMethods[_selectedPaymentMethod]['method']
            as payment_model.PaymentMethod;
    final paymentProvider = Provider.of<PaymentProvider>(
      contextArg,
      listen: false,
    );
    final orderProvider = Provider.of<OrderProvider>(contextArg, listen: false);
    final authProvider = Provider.of<AuthProvider>(contextArg, listen: false);
    final cartProvider = Provider.of<CartProvider>(contextArg, listen: false);

    setState(() {
      _isProcessing = true;
    });

    try {
      String? orderId;
      String? paymentId;

      // Check if this is the new flow (no existing order) or old flow (existing order)
      if (widget.orderId == null) {
        // NEW FLOW: Create order first, then process payment
        if (widget.cartItems == null || widget.deliveryAddress == null) {
          throw Exception('Missing cart items or delivery address');
        }

        // Get user data
        final userData = authProvider.user;
        if (userData == null) {
          throw Exception('User data not available');
        }

        // Create the order first
        orderId = await orderProvider.createOrder(
          cartItems: widget.cartItems!,
          subtotal: widget.subtotal ?? 0.0,
          deliveryFee: widget.deliveryFee ?? 0.0,
          discount: 0.0, // No discount for now
          totalAmount: widget.amount,
          deliveryAddress: widget.deliveryAddress!,
          paymentMethod: selectedMethod.name,
          deliveryNotes: null, // No delivery notes for now
        );

        if (orderId == null) {
          throw Exception('Failed to create order');
        }

        // Create payment record
        paymentId = await paymentProvider.createPayment(
          orderId: orderId,
          amount: widget.amount,
          method: selectedMethod,
        );

        if (paymentId == null) {
          throw Exception('Failed to create payment record');
        }
      } else {
        // OLD FLOW: Order already exists, just process payment
        orderId = widget.orderId!;

        // Create payment record
        paymentId = await paymentProvider.createPayment(
          orderId: orderId,
          amount: widget.amount,
          method: selectedMethod,
        );

        if (paymentId == null) {
          throw Exception('Failed to create payment record');
        }
      }

      // For Cash on Delivery, mark as pending and proceed
      if (selectedMethod == payment_model.PaymentMethod.cashOnDelivery) {
        // Update payment status
        await paymentProvider.updatePaymentStatus(
          paymentId: paymentId,
          status: payment_model.PaymentStatus.pending,
        );

        // Update order payment info
        await orderProvider.updateOrderPaymentInfo(
          orderId: orderId,
          paymentId: paymentId,
          paymentStatus: order_model.PaymentStatus.pending,
        );

        // Clear cart only for new flow
        if (widget.orderId == null) {
          await cartProvider.clearCart();
        }

        if (mounted) {
          navigator.pushReplacementNamed(
            PaymentSuccessScreen.routeName,
            arguments: {
              'orderId': orderId,
              'paymentId': paymentId,
              'amount': widget.amount,
              'method': selectedMethod,
            },
          );
        }
        return;
      }

      // For other payment methods, simulate payment gateway
      // In a real app, this would integrate with Razorpay or other payment gateways
      await Future.delayed(const Duration(seconds: 2));

      // Simulate successful payment (90% success rate)
      final isSuccess = DateTime.now().millisecondsSinceEpoch % 10 != 0;

      if (isSuccess) {
        // Update payment status
        await paymentProvider.updatePaymentStatus(
          paymentId: paymentId,
          status: payment_model.PaymentStatus.completed,
          transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
          paymentGatewayResponse: '{"status": "success"}',
        );

        // Update order payment info
        await orderProvider.updateOrderPaymentInfo(
          orderId: orderId,
          paymentId: paymentId,
          paymentStatus: order_model.PaymentStatus.completed,
          transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        );

        // Clear cart only for new flow
        if (widget.orderId == null) {
          await cartProvider.clearCart();
        }

        if (mounted) {
          navigator.pushReplacementNamed(
            PaymentSuccessScreen.routeName,
            arguments: {
              'orderId': orderId,
              'paymentId': paymentId,
              'amount': widget.amount,
              'method': selectedMethod,
            },
          );
        }
      } else {
        // Update payment status
        await paymentProvider.updatePaymentStatus(
          paymentId: paymentId,
          status: payment_model.PaymentStatus.failed,
          failureReason: 'Transaction declined by bank',
        );

        // Update order payment info
        await orderProvider.updateOrderPaymentInfo(
          orderId: orderId,
          paymentId: paymentId,
          paymentStatus: order_model.PaymentStatus.failed,
        );

        if (mounted) {
          navigator.pushReplacementNamed(
            PaymentFailureScreen.routeName,
            arguments: {
              'orderId': orderId,
              'paymentId': paymentId,
              'amount': widget.amount,
              'method': selectedMethod,
              'errorMessage': 'Transaction declined by bank',
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Payment processing failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
