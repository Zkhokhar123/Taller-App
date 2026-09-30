import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../models/tailor_order.dart';
import 'payment_repository.dart';

class OrderRepository {
  final _uuid = const Uuid();
  final _payments = PaymentRepository();

  static const _joinSelect = '''
    SELECT o.*,
      c.name AS customer_name,
      c.phone AS customer_phone,
      k.name AS karigar_name
    FROM orders o
    LEFT JOIN customers c ON c.id = o.customer_id
    LEFT JOIN karigars k ON k.id = o.karigar_id
  ''';

  Future<int> _nextOrderNo() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      'SELECT MAX(order_no) AS max_no FROM orders',
    );
    final maxNo = result.first['max_no'] as int?;
    return (maxNo ?? 1000) + 1;
  }

  Future<List<TailorOrder>> getAll({
    String query = '',
    OrderStatus? status,
  }) async {
    final db = await AppDatabase.instance.database;
    final where = <String>[];
    final args = <Object?>[];

    if (status != null) {
      where.add('o.status = ?');
      args.add(status.name);
    }
    if (query.trim().isNotEmpty) {
      where.add(
        '(c.name LIKE ? OR c.phone LIKE ? OR o.garment_type LIKE ? OR CAST(o.order_no AS TEXT) LIKE ?)',
      );
      final q = '%${query.trim()}%';
      args.addAll([q, q, q, q]);
    }

    final sql = StringBuffer(_joinSelect);
    if (where.isNotEmpty) {
      sql.write(' WHERE ${where.join(' AND ')}');
    }
    sql.write(' ORDER BY o.order_no DESC');

    final rows = await db.rawQuery(sql.toString(), args);
    return rows.map(TailorOrder.fromMap).toList();
  }

  Future<TailorOrder?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '$_joinSelect WHERE o.id = ? LIMIT 1',
      [id],
    );
    if (rows.isEmpty) return null;
    return TailorOrder.fromMap(rows.first);
  }

  Future<TailorOrder> create({
    required String customerId,
    String? karigarId,
    required String garmentType,
    OrderStatus status = OrderStatus.pending,
    required DateTime orderDate,
    DateTime? deliveryDate,
    required double totalAmount,
    required double advanceAmount,
    String? measurements,
    String? instructions,
    List<String> tagIds = const [],
  }) async {
    final order = TailorOrder(
      id: _uuid.v4(),
      orderNo: await _nextOrderNo(),
      customerId: customerId,
      karigarId: karigarId,
      garmentType: garmentType.trim(),
      status: status,
      orderDate: orderDate,
      deliveryDate: deliveryDate,
      totalAmount: totalAmount,
      advanceAmount: advanceAmount,
      measurements: measurements?.trim().isEmpty == true ? null : measurements?.trim(),
      instructions: instructions?.trim().isEmpty == true ? null : instructions?.trim(),
      tagIds: tagIds,
      createdAt: DateTime.now(),
    );
    final db = await AppDatabase.instance.database;
    await db.insert('orders', order.toMap());
    if (advanceAmount > 0) {
      await _payments.recordInitialAdvance(
        orderId: order.id,
        amount: advanceAmount,
        paidAt: orderDate,
      );
    }
    return (await getById(order.id))!;
  }

  Future<void> update(TailorOrder order) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  /// Mark received + clear remaining payment (باقی رقم وصول).
  Future<TailorOrder> markReceivedByCustomer(String orderId) async {
    final existing = await getById(orderId);
    if (existing == null) {
      throw Exception('آرڈر نہیں ملا');
    }

    await _payments.clearRemainingOnReceive(orderId);

    final refreshed = await getById(orderId);
    final updated = (refreshed ?? existing).copyWith(
      status: OrderStatus.delivered,
      receivedAt: DateTime.now(),
      advanceAmount: existing.totalAmount,
    );
    await update(updated);
    return (await getById(orderId))!;
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count({OrderStatus? status}) async {
    final db = await AppDatabase.instance.database;
    if (status == null) {
      final result = await db.rawQuery('SELECT COUNT(*) AS c FROM orders');
      return (result.first['c'] as int?) ?? 0;
    }
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM orders WHERE status = ?',
      [status.name],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  Future<double> pendingBalance() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(total_amount - advance_amount), 0) AS bal
      FROM orders
      WHERE status != ?
        AND (total_amount - advance_amount) > 0.009
    ''', [OrderStatus.cancelled.name]);
    return (result.first['bal'] as num?)?.toDouble() ?? 0;
  }
}
