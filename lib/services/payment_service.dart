import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_kirana/models/payment_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Razorpay API keys (in a real app, these would be stored in .env file)
  String get _razorpayKeyId => dotenv.env['RAZORPAY_KEY_ID'] ?? 'rzp_test_1DP5mmOlF5G5ag';
  String get _razorpayKeySecret => dotenv.env['RAZORPAY_KEY_SECRET'] ?? 'secret_key_placeholder';

  // Create a new payment record
  Future<String> createPayment({
    required String orderId,
    required String userId,
    required double amount,
    required PaymentMethod method,
  }) async {
    try {
      // Create payment document
      final paymentRef = _firestore.collection('payments').doc();
      
      final payment = PaymentModel(
        id: paymentRef.id,
        orderId: orderId,
        userId: userId,
        amount: amount,
        status: PaymentStatus.pending,
        method: method,
        timestamp: DateTime.now(),
      );

      // Save payment to Firestore
      await paymentRef.set(payment.toMap());
      
      return paymentRef.id;
    } catch (e) {
      throw Exception('Failed to create payment: ${e.toString()}');
    }
  }

  // Get payment by ID
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      final docSnapshot = await _firestore.collection('payments').doc(paymentId).get();

      if (!docSnapshot.exists) {
        return null;
      }

      return PaymentModel.fromMap(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to get payment: ${e.toString()}');
    }
  }

  // Get payments for an order
  Future<List<PaymentModel>> getPaymentsForOrder(String orderId) async {
    try {
      final querySnapshot = await _firestore
          .collection('payments')
          .where('orderId', isEqualTo: orderId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get payments for order: ${e.toString()}');
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    String? transactionId,
    String? paymentGatewayResponse,
    String? failureReason,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'status': status.name,
      };

      if (transactionId != null) {
        updateData['transactionId'] = transactionId;
      }
      
      if (paymentGatewayResponse != null) {
        updateData['paymentGatewayResponse'] = paymentGatewayResponse;
      }
      
      if (failureReason != null) {
        updateData['failureReason'] = failureReason;
      }

      await _firestore.collection('payments').doc(paymentId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update payment status: ${e.toString()}');
    }
  }

  // Process refund
  Future<void> processRefund({
    required String paymentId,
    String? refundId,
  }) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': PaymentStatus.refunded.name,
        'refundId': refundId,
        'refundTimestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to process refund: ${e.toString()}');
    }
  }

  // Initialize Razorpay payment (in a real app, this would make API calls to Razorpay)
  Future<Map<String, dynamic>> initializeRazorpayPayment({
    required String orderId,
    required double amount,
    required String currency,
    required String name,
    required String description,
    required String email,
    required String contact,
  }) async {
    try {
      // In a real app, this would make an API call to Razorpay to create an order
      // For now, we'll simulate the response
      
      // Convert amount to paise (Razorpay uses smallest currency unit)
      final amountInPaise = (amount * 100).toInt();
      
      return {
        'key': _razorpayKeyId,
        'amount': amountInPaise,
        'name': name,
        'description': description,
        'order_id': 'order_${DateTime.now().millisecondsSinceEpoch}',
        'prefill': {
          'email': email,
          'contact': contact,
        },
        'theme': {
          'color': '#6C9A8B',
        },
      };
    } catch (e) {
      throw Exception('Failed to initialize Razorpay payment: ${e.toString()}');
    }
  }

  // Verify Razorpay payment (in a real app, this would verify the payment signature)
  Future<bool> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      // In a real app, this would verify the payment signature with Razorpay
      // For now, we'll simulate the verification
      
      // Simulate successful verification
      return true;
    } catch (e) {
      throw Exception('Failed to verify Razorpay payment: ${e.toString()}');
    }
  }
}
