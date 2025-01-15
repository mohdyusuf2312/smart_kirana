import 'package:flutter/material.dart';
import 'package:smart_kirana/models/payment_model.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  final AuthProvider _authProvider;

  PaymentModel? _currentPayment;
  List<PaymentModel> _orderPayments = [];
  bool _isLoading = false;
  String? _error;

  PaymentProvider({required AuthProvider authProvider}) : _authProvider = authProvider;

  // Getters
  PaymentModel? get currentPayment => _currentPayment;
  List<PaymentModel> get orderPayments => _orderPayments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create a new payment
  Future<String?> createPayment({
    required String orderId,
    required double amount,
    required PaymentMethod method,
  }) async {
    if (_authProvider.currentUser == null) {
      _setError('User not authenticated');
      return null;
    }

    _setLoading(true);
    try {
      final paymentId = await _paymentService.createPayment(
        orderId: orderId,
        userId: _authProvider.currentUser!.uid,
        amount: amount,
        method: method,
      );

      await getPaymentById(paymentId);
      return paymentId;
    } catch (e) {
      _setError('Failed to create payment: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Get payment by ID
  Future<void> getPaymentById(String paymentId) async {
    _setLoading(true);
    try {
      final payment = await _paymentService.getPaymentById(paymentId);
      _currentPayment = payment;
      notifyListeners();
    } catch (e) {
      _setError('Failed to get payment: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Get payments for an order
  Future<void> getPaymentsForOrder(String orderId) async {
    _setLoading(true);
    try {
      _orderPayments = await _paymentService.getPaymentsForOrder(orderId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to get payments for order: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update payment status
  Future<bool> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    String? transactionId,
    String? paymentGatewayResponse,
    String? failureReason,
  }) async {
    _setLoading(true);
    try {
      await _paymentService.updatePaymentStatus(
        paymentId: paymentId,
        status: status,
        transactionId: transactionId,
        paymentGatewayResponse: paymentGatewayResponse,
        failureReason: failureReason,
      );

      // Update local payment if it's the current payment
      if (_currentPayment != null && _currentPayment!.id == paymentId) {
        _currentPayment = _currentPayment!.copyWith(
          status: status,
          transactionId: transactionId ?? _currentPayment!.transactionId,
        );
      }

      // Update in order payments list if present
      final index = _orderPayments.indexWhere((p) => p.id == paymentId);
      if (index >= 0) {
        _orderPayments[index] = _orderPayments[index].copyWith(
          status: status,
          transactionId: transactionId ?? _orderPayments[index].transactionId,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update payment status: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Process refund
  Future<bool> processRefund({
    required String paymentId,
    String? refundId,
  }) async {
    _setLoading(true);
    try {
      await _paymentService.processRefund(
        paymentId: paymentId,
        refundId: refundId,
      );

      // Update local payment if it's the current payment
      if (_currentPayment != null && _currentPayment!.id == paymentId) {
        _currentPayment = _currentPayment!.copyWith(
          status: PaymentStatus.refunded,
          refundId: refundId,
          refundTimestamp: DateTime.now(),
        );
      }

      // Update in order payments list if present
      final index = _orderPayments.indexWhere((p) => p.id == paymentId);
      if (index >= 0) {
        _orderPayments[index] = _orderPayments[index].copyWith(
          status: PaymentStatus.refunded,
          refundId: refundId,
          refundTimestamp: DateTime.now(),
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to process refund: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Initialize Razorpay payment
  Future<Map<String, dynamic>?> initializeRazorpayPayment({
    required String orderId,
    required double amount,
    required String name,
    required String description,
  }) async {
    if (_authProvider.currentUser == null || _authProvider.userData == null) {
      _setError('User not authenticated');
      return null;
    }

    _setLoading(true);
    try {
      final userData = _authProvider.userData!;
      
      final razorpayOptions = await _paymentService.initializeRazorpayPayment(
        orderId: orderId,
        amount: amount,
        currency: 'INR',
        name: name,
        description: description,
        email: userData.email,
        contact: userData.phone,
      );

      return razorpayOptions;
    } catch (e) {
      _setError('Failed to initialize Razorpay payment: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Verify Razorpay payment
  Future<bool> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    _setLoading(true);
    try {
      final isVerified = await _paymentService.verifyRazorpayPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );

      return isVerified;
    } catch (e) {
      _setError('Failed to verify Razorpay payment: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearCurrentPayment() {
    _currentPayment = null;
    notifyListeners();
  }

  void clearOrderPayments() {
    _orderPayments = [];
    notifyListeners();
  }
}
