enum OrderStatus {
  pending,
  inProgress,
  ready,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get labelUr {
    switch (this) {
      case OrderStatus.pending:
        return 'زیرِ التوا';
      case OrderStatus.inProgress:
        return 'کام جاری';
      case OrderStatus.ready:
        return 'تیار';
      case OrderStatus.delivered:
        return 'گاہک کو مل گیا';
      case OrderStatus.cancelled:
        return 'منسوخ';
    }
  }

  static OrderStatus fromStorage(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

class TailorOrder {
  final String id;
  final int orderNo;
  final String customerId;
  final String? karigarId;
  final String garmentType;
  final OrderStatus status;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final DateTime? receivedAt;
  final double totalAmount;
  final double advanceAmount;
  final String? measurements;
  final String? instructions;
  final List<String> tagIds;
  final DateTime createdAt;

  final String? customerName;
  final String? customerPhone;
  final String? karigarName;

  const TailorOrder({
    required this.id,
    required this.orderNo,
    required this.customerId,
    this.karigarId,
    required this.garmentType,
    required this.status,
    required this.orderDate,
    this.deliveryDate,
    this.receivedAt,
    required this.totalAmount,
    required this.advanceAmount,
    this.measurements,
    this.instructions,
    this.tagIds = const [],
    required this.createdAt,
    this.customerName,
    this.customerPhone,
    this.karigarName,
  });

  bool get isReceivedByCustomer =>
      status == OrderStatus.delivered || receivedAt != null;

  double get balance => (totalAmount - advanceAmount).clamp(0, double.infinity);

  TailorOrder copyWith({
    String? id,
    int? orderNo,
    String? customerId,
    String? karigarId,
    bool clearKarigar = false,
    String? garmentType,
    OrderStatus? status,
    DateTime? orderDate,
    DateTime? deliveryDate,
    bool clearDelivery = false,
    DateTime? receivedAt,
    bool clearReceived = false,
    double? totalAmount,
    double? advanceAmount,
    String? measurements,
    String? instructions,
    List<String>? tagIds,
    DateTime? createdAt,
    String? customerName,
    String? customerPhone,
    String? karigarName,
  }) {
    return TailorOrder(
      id: id ?? this.id,
      orderNo: orderNo ?? this.orderNo,
      customerId: customerId ?? this.customerId,
      karigarId: clearKarigar ? null : (karigarId ?? this.karigarId),
      garmentType: garmentType ?? this.garmentType,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: clearDelivery ? null : (deliveryDate ?? this.deliveryDate),
      receivedAt: clearReceived ? null : (receivedAt ?? this.receivedAt),
      totalAmount: totalAmount ?? this.totalAmount,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      measurements: measurements ?? this.measurements,
      instructions: instructions ?? this.instructions,
      tagIds: tagIds ?? this.tagIds,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      karigarName: karigarName ?? this.karigarName,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'order_no': orderNo,
        'customer_id': customerId,
        'karigar_id': karigarId,
        'garment_type': garmentType,
        'status': status.name,
        'order_date': orderDate.toIso8601String(),
        'delivery_date': deliveryDate?.toIso8601String(),
        'received_at': receivedAt?.toIso8601String(),
        'total_amount': totalAmount,
        'advance_amount': advanceAmount,
        'measurements': measurements,
        'instructions': instructions,
        'tag_ids': tagIds.join(','),
        'created_at': createdAt.toIso8601String(),
      };

  factory TailorOrder.fromMap(Map<String, Object?> map) {
    final tagRaw = map['tag_ids'] as String?;
    return TailorOrder(
      id: map['id'] as String,
      orderNo: map['order_no'] as int,
      customerId: map['customer_id'] as String,
      karigarId: map['karigar_id'] as String?,
      garmentType: map['garment_type'] as String,
      status: OrderStatus.fromStorage(map['status'] as String),
      orderDate: DateTime.parse(map['order_date'] as String),
      deliveryDate: map['delivery_date'] != null
          ? DateTime.parse(map['delivery_date'] as String)
          : null,
      receivedAt: map['received_at'] != null
          ? DateTime.parse(map['received_at'] as String)
          : null,
      totalAmount: (map['total_amount'] as num).toDouble(),
      advanceAmount: (map['advance_amount'] as num).toDouble(),
      measurements: map['measurements'] as String?,
      instructions: map['instructions'] as String?,
      tagIds: (tagRaw == null || tagRaw.isEmpty)
          ? const []
          : tagRaw.split(',').where((e) => e.isNotEmpty).toList(),
      createdAt: DateTime.parse(map['created_at'] as String),
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      karigarName: map['karigar_name'] as String?,
    );
  }
}
