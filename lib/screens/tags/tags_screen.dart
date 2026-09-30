import 'package:flutter/material.dart';

import '../../core/l10n/urdu.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tag_item.dart';
import '../../repositories/tag_repository.dart';
import '../../widgets/common_widgets.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  final _repo = TagRepository();
  List<TagItem> _items = [];
  bool _loading = true;

  static const _palette = [
    0xFFDC2626,
    0xFFD97706,
    0xFF0F766E,
    0xFF2563EB,
    0xFF7C3AED,
    0xFFDB2777,
    0xFF0B1F33,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _repo.getAll();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upsert({TagItem? tag}) async {
    final nameCtrl = TextEditingController(text: tag?.name ?? '');
    int color = tag?.colorValue ?? _palette.first;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(tag == null ? 'نیا ٹیگ' : 'ٹیگ ترمیم'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'ٹیگ کا نام'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: _palette.map((c) {
                      final selected = color == c;
                      return GestureDetector(
                        onTap: () => setLocal(() => color = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(color: AppColors.navy, width: 3)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('منسوخ'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('محفوظ'),
                ),
              ],
            );
          },
        );
      },
    );

    final name = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (saved != true || name.isEmpty) return;

    if (tag == null) {
      await _repo.create(name: name, colorValue: color);
    } else {
      await _repo.update(tag.copyWith(name: name, colorValue: color));
    }
    _load();
  }

  Future<void> _delete(TagItem tag) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ٹیگ حذف کریں؟'),
        content: Text('"${tag.name}" ہٹائیں؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('منسوخ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _repo.delete(tag.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Ur.tags)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _upsert(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? EmptyState(
                  icon: Icons.sell_outlined,
                  title: 'کوئی ٹیگ نہیں',
                  subtitle: 'فوری، VIP یا الٹر جیسے ٹیگ بنائیں۔',
                  actionLabel: 'ٹیگ شامل کریں',
                  onAction: () => _upsert(),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final t = _items[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: t.color),
                        title: Text(
                          t.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _upsert(tag: t),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              onPressed: () => _delete(t),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
