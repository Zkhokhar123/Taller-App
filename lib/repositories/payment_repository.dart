import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../models/payment_record.dart';
import '../models/tailor_order.dart';

class PaymentRepository {
  final _uuid = const Uuid();

  static const _join = '''
    SELECT p.*,
      o.order_no AS order_no,
      o.garment_type AS garment_type,
      c.name AS customer_name
    FROM payments p
    LEFT JOIN orders o ON o.id = p.order_id
    LEFT JOIN customers c ON c.id = o.customer_id
  ''';

  Future<List<PaymentRecord>> forOrder(String orderId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '$_join WHERE p.order_id = ? ORDER BY p.paid_at DESC',
      [orderId],
    );
    return rows.map(PaymentRecord.fromMap).toList();
  }

  Future<PaymentRecord> addPayment({
    required String orderId,
    required double amount,
    required String type,
    DateTime? paidAt,
    String? note,
  }) async {
    if (amount <= 0) {
      throw Exception('رقم صفر سے زیادہ ہونی چاہیے');
    }

    final db = await AppDatabase.instance.database;
    final orderRows = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
      limit: 1,
    );
    if (orderRows.isEmpty) throw Exception('آرڈر نہیں ملا');

    final order = TailorOrder.fromMap(orderRows.first);
    final newPaid = order.advanceAmount + amount;
    if (newPaid > order.totalAmount + 0.01) {
      throw Exception('ادائیگی کل رقم سے زیادہ نہیں ہو سکتی');
    }

    final record = PaymentRecord(
      id: _uuid.v4(),
      orderId: orderId,
      amount: amount,
      type: type,
      paidAt: paidAt ?? DateTime.now(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      createdAt: DateTime.now(),
    );

    await db.insert('payments', record.toMap());
    await db.update(
      'orders',
      {'advance_amount': newPaid},
      where: 'id = ?',
      whereArgs: [orderId],
    );

    return record;
  }

  /// On customer receive: take remaining balance as clearance and fully pay.
  Future<void> clearRemainingOnReceive(String orderId) async {
    final db = await AppDatabase.instance.database;
    final orderRows = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
      limit: 1,
    );
    if (orderRows.isEmpty) return;

    final order = TailorOrder.fromMap(orderRows.first);
    final remaining = order.balance;
    if (remaining > 0.009) {
      await addPayment(
        orderId: orderId,
        amount: remaining,
        type: 'clearance',
        note: 'گاہک وصول پر فل ادائیگی',
      );
    } else {
      // Ensure paid equals total
      await db.update(
        'orders',
        {'advance_amount': order.totalAmount},
        where: 'id = ?',
        whereArgs: [orderId],
      );
    }
  }

  Future<void> recordInitialAdvance({
    required String orderId,
    required double amount,
    required DateTime paidAt,
  }) async {
    if (amount <= 0) return;
    final db = await AppDatabase.instance.database;
    final record = PaymentRecord(
      id: _uuid.v4(),
      orderId: orderId,
      amount: amount,
      type: 'advance',
      paidAt: paidAt,
      note: 'آرڈر پر ایڈوانس',
      createdAt: DateTime.now(),
    );
    await db.insert('payments', record.toMap());
  }

  Future<MonthPaymentSummary> monthSummary(DateTime month) async {
    final db = await AppDatabase.instance.database;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final paymentRows = await db.rawQuery(
      '''
      $_join
      WHERE p.paid_at >= ? AND p.paid_at < ?
      ORDER BY p.paid_at DESC
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final payments = paymentRows.map(PaymentRecord.fromMap).toList();
    final received = payments.fold<double>(0, (s, p) => s + p.amount);

    final pendingRows = await db.rawQuery('''
      SELECT o.id, o.order_no, o.garment_type, o.total_amount, o.advance_amount,
             o.order_date, o.status, o.received_at, c.name AS customer_name
      FROM orders o
      LEFT JOIN customers c ON c.id = o.customer_id
      WHERE o.status != ?
        AND (o.total_amount - o.advance_amount) > 0.009
      ORDER BY o.order_date DESC
    ''', [OrderStatus.cancelled.name]);

    final pendingOrders = pendingRows.map((m) {
      final total = (m['total_amount'] as num).toDouble();
      final paid = (m['advance_amount'] as num).toDouble();
      return TailorOrderBalance(
        orderId: m['id'] as String,
        orderNo: m['order_no'] as int,
        garmentType: m['garment_type'] as String,
        customerName: (m['customer_name'] as String?) ?? 'گاہک',
        totalAmount: total,
        paidAmount: paid,
        balance: (total - paid).clamp(0, double.infinity),
        orderDate: DateTime.parse(m['order_date'] as String),
        isReceived: m['status'] == OrderStatus.delivered.name ||
            m['received_at'] != null,
      );
    }).toList();

    final outstanding = pendingOrders.fold<double>(0, (s, o) => s + o.balance);

    return MonthPaymentSummary(
      receivedThisMonth: received,
      outstandingBalance: outstanding,
      pendingSuits: pendingOrders.length,
      payments: payments,
      pendingOrders: pendingOrders,
    );
  }
}
