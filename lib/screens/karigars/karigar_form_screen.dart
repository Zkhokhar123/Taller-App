import 'package:flutter/material.dart';

import '../../models/karigar.dart';
import '../../repositories/karigar_repository.dart';

class KarigarFormScreen extends StatefulWidget {
  final Karigar? karigar;

  const KarigarFormScreen({super.key, this.karigar});

  @override
  State<KarigarFormScreen> createState() => _KarigarFormScreenState();
}

class _KarigarFormScreenState extends State<KarigarFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = KarigarRepository();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _specialty;
  late final TextEditingController _notes;
  bool _saving = false;

  bool get _isEdit => widget.karigar != null;

  @override
  void initState() {
    super.initState();
    final k = widget.karigar;
    _name = TextEditingController(text: k?.name ?? '');
    _phone = TextEditingController(text: k?.phone ?? '');
    _specialty = TextEditingController(text: k?.specialty ?? '');
    _notes = TextEditingController(text: k?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _specialty.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await _repo.update(
          widget.karigar!.copyWith(
            name: _name.text,
            phone: _phone.text,
            specialty: _specialty.text,
            notes: _notes.text,
          ),
        );
      } else {
        await _repo.create(
          name: _name.text,
          phone: _phone.text,
          specialty: _specialty.text,
          notes: _notes.text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('کاریگر حذف کریں؟'),
        content: const Text('یہ عمل واپس نہیں ہو سکتا۔'),
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
    await _repo.delete(widget.karigar!.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'کاریگر ترمیم' : 'نیا کاریگر'),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'نام *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'نام ضروری ہے' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'فون'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _specialty,
              decoration: const InputDecoration(
                labelText: 'مہارت',
                hintText: 'مثلاً کوٹ، کڑھائی',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'نوٹس'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'محفوظ ہو رہا ہے...' : 'کاریگر محفوظ کریں'),
            ),
          ],
        ),
      ),
    );
  }
}
