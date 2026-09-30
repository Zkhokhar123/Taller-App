import 'package:flutter/material.dart';

import '../../core/l10n/urdu.dart';
import '../../core/theme/app_theme.dart';
import '../../models/karigar.dart';
import '../../repositories/karigar_repository.dart';
import '../../widgets/common_widgets.dart';
import 'karigar_form_screen.dart';

class KarigarsScreen extends StatefulWidget {
  const KarigarsScreen({super.key});

  @override
  State<KarigarsScreen> createState() => _KarigarsScreenState();
}

class _KarigarsScreenState extends State<KarigarsScreen> {
  final _repo = KarigarRepository();
  final _search = TextEditingController();
  List<Karigar> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _repo.getAll(query: _search.text);
      if (!mounted) return;
      setState(() => _items = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({Karigar? karigar}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => KarigarFormScreen(karigar: karigar),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Ur.karigar)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.person_add_alt),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'کاریگر تلاش کریں',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => _load(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? EmptyState(
                        icon: Icons.handyman_outlined,
                        title: 'کوئی کاریگر نہیں',
                        subtitle: 'کام تفویض اور سلپ کے لیے کاریگر شامل کریں۔',
                        actionLabel: 'کاریگر شامل کریں',
                        onAction: () => _openForm(),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final k = _items[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColors.navy.withValues(alpha: 0.1),
                                  foregroundColor: AppColors.navy,
                                  child: const Icon(Icons.handyman, size: 20),
                                ),
                                title: Text(
                                  k.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  [
                                    if ((k.specialty ?? '').isNotEmpty)
                                      k.specialty,
                                    if ((k.phone ?? '').isNotEmpty) k.phone,
                                  ].join(' · '),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openForm(karigar: k),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
