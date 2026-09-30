import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../models/customer.dart';

class CustomerRepository {
  final _uuid = const Uuid();

  Future<List<Customer>> getAll({String query = ''}) async {
    final db = await AppDatabase.instance.database;
    final rows = query.trim().isEmpty
        ? await db.query('customers', orderBy: 'name COLLATE NOCASE ASC')
        : await db.query(
            'customers',
            where: 'name LIKE ? OR phone LIKE ?',
            whereArgs: ['%$query%', '%$query%'],
            orderBy: 'name COLLATE NOCASE ASC',
          );
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  Future<Customer> create({
    required String name,
    String? phone,
    String? address,
    String? notes,
  }) async {
    final customer = Customer(
      id: _uuid.v4(),
      name: name.trim(),
      phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
      address: address?.trim().isEmpty == true ? null : address?.trim(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      createdAt: DateTime.now(),
    );
    final db = await AppDatabase.instance.database;
    await db.insert('customers', customer.toMap());
    return customer;
  }

  Future<void> update(Customer customer) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM customers');
    return (result.first['c'] as int?) ?? 0;
  }
}
