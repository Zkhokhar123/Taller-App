import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../models/karigar.dart';

class KarigarRepository {
  final _uuid = const Uuid();

  Future<List<Karigar>> getAll({String query = ''}) async {
    final db = await AppDatabase.instance.database;
    final rows = query.trim().isEmpty
        ? await db.query('karigars', orderBy: 'name COLLATE NOCASE ASC')
        : await db.query(
            'karigars',
            where: 'name LIKE ? OR phone LIKE ? OR specialty LIKE ?',
            whereArgs: ['%$query%', '%$query%', '%$query%'],
            orderBy: 'name COLLATE NOCASE ASC',
          );
    return rows.map(Karigar.fromMap).toList();
  }

  Future<Karigar?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('karigars', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Karigar.fromMap(rows.first);
  }

  Future<Karigar> create({
    required String name,
    String? phone,
    String? specialty,
    String? notes,
  }) async {
    final karigar = Karigar(
      id: _uuid.v4(),
      name: name.trim(),
      phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
      specialty: specialty?.trim().isEmpty == true ? null : specialty?.trim(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      createdAt: DateTime.now(),
    );
    final db = await AppDatabase.instance.database;
    await db.insert('karigars', karigar.toMap());
    return karigar;
  }

  Future<void> update(Karigar karigar) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'karigars',
      karigar.toMap(),
      where: 'id = ?',
      whereArgs: [karigar.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('karigars', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM karigars');
    return (result.first['c'] as int?) ?? 0;
  }
}
