class PaymentRecord {
  final String id;
  final String orderId;
  final double amount;
  final String type; // advance | partial | clearance
  final DateTime paidAt;
  final String? note;
  final DateTime createdAt;

  // Joined
  final int? orderNo;
  final String? customerName;
  final String? garmentType;

  const PaymentRecord({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.type,
    required this.paidAt,
    this.note,
    required this.createdAt,
    this.orderNo,
    this.customerName,
    this.garmentType,
  });

  String get typeUr {
    switch (type) {
      case 'advance':
        return 'ایڈوانس';
      case 'clearance':
        return 'فل کلیئر';
      default:
        return 'جزوی ادائیگی';
    }
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'order_id': orderId,
        'amount': amount,
        'type': type,
        'paid_at': paidAt.toIso8601String(),
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };

  factory PaymentRecord.fromMap(Map<String, Object?> map) => PaymentRecord(
        id: map['id'] as String,
        orderId: map['order_id'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: map['type'] as String,
        paidAt: DateTime.parse(map['paid_at'] as String),
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        orderNo: map['order_no'] as int?,
        customerName: map['customer_name'] as String?,
        garmentType: map['garment_type'] as String?,
      );
}

class MonthPaymentSummary {
  final double receivedThisMonth;
  final double outstandingBalance;
  final int pendingSuits;
  final List<PaymentRecord> payments;
  final List<TailorOrderBalance> pendingOrders;

  const MonthPaymentSummary({
    required this.receivedThisMonth,
    required this.outstandingBalance,
    required this.pendingSuits,
    required this.payments,
    required this.pendingOrders,
  });
}

class TailorOrderBalance {
  final String orderId;
  final int orderNo;
  final String garmentType;
  final String customerName;
  final double totalAmount;
  final double paidAmount;
  final double balance;
  final DateTime orderDate;
  final bool isReceived;

  const TailorOrderBalance({
    required this.orderId,
    required this.orderNo,
    required this.garmentType,
    required this.customerName,
    required this.totalAmount,
    required this.paidAmount,
    required this.balance,
    required this.orderDate,
    required this.isReceived,
  });
}
