import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
}

enum PaymentMethod {
  cashOnDelivery,
  razorpay,
  upi,
  creditCard,
  debitCard,
  netBanking,
}

class PaymentModel {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final PaymentStatus status;
  final PaymentMethod method;
  final DateTime timestamp;
  final String? transactionId;
  final String? paymentGatewayResponse;
  final String? failureReason;
  final String? refundId;
  final DateTime? refundTimestamp;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.status,
    required this.method,
    required this.timestamp,
    this.transactionId,
    this.paymentGatewayResponse,
    this.failureReason,
    this.refundId,
    this.refundTimestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'status': status.name,
      'method': method.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'transactionId': transactionId,
      'paymentGatewayResponse': paymentGatewayResponse,
      'failureReason': failureReason,
      'refundId': refundId,
      'refundTimestamp': refundTimestamp != null
          ? Timestamp.fromDate(refundTimestamp!)
          : null,
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map, String docId) {
    return PaymentModel(
      id: docId,
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == map['method'],
        orElse: () => PaymentMethod.cashOnDelivery,
      ),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      transactionId: map['transactionId'],
      paymentGatewayResponse: map['paymentGatewayResponse'],
      failureReason: map['failureReason'],
      refundId: map['refundId'],
      refundTimestamp: (map['refundTimestamp'] as Timestamp?)?.toDate(),
    );
  }

  // Create a copy of this payment with updated fields
  PaymentModel copyWith({
    String? id,
    String? orderId,
    String? userId,
    double? amount,
    PaymentStatus? status,
    PaymentMethod? method,
    DateTime? timestamp,
    String? transactionId,
    String? paymentGatewayResponse,
    String? failureReason,
    String? refundId,
    DateTime? refundTimestamp,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      method: method ?? this.method,
      timestamp: timestamp ?? this.timestamp,
      transactionId: transactionId ?? this.transactionId,
      paymentGatewayResponse:
          paymentGatewayResponse ?? this.paymentGatewayResponse,
      failureReason: failureReason ?? this.failureReason,
      refundId: refundId ?? this.refundId,
      refundTimestamp: refundTimestamp ?? this.refundTimestamp,
    );
  }
}
