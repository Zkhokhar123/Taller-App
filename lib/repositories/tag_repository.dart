import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../models/tag_item.dart';

class TagRepository {
  final _uuid = const Uuid();

  Future<List<TagItem>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('tags', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(TagItem.fromMap).toList();
  }

  Future<TagItem> create({
    required String name,
    required int colorValue,
  }) async {
    final tag = TagItem(
      id: _uuid.v4(),
      name: name.trim(),
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );
    final db = await AppDatabase.instance.database;
    await db.insert('tags', tag.toMap());
    return tag;
  }

  Future<void> update(TagItem tag) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'tags',
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }
}
