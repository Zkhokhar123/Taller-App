import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/urdu.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/customer.dart';
import '../../models/karigar.dart';
import '../../models/tailor_order.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/karigar_repository.dart';
import '../../repositories/order_repository.dart';

/// TikTok-style tailor "Add New" order slip — fully Urdu + RTL.
class OrderFormScreen extends StatefulWidget {
  final TailorOrder? order;

  const OrderFormScreen({super.key, this.order});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orders = OrderRepository();
  final _customers = CustomerRepository();
  final _karigars = KarigarRepository();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _garment;
  late final TextEditingController _instructions;
  late final TextEditingController _quantity;
  late final TextEditingController _rate;
  late final TextEditingController _total;
  late final TextEditingController _advance;
  final Map<String, TextEditingController> _measureCtrls = {
    for (final f in kMeasureFields) f.key: TextEditingController(),
  };

  List<Customer> _customerList = [];
  List<Karigar> _karigarList = [];
  String? _customerId;
  String? _karigarId;
  OrderStatus _status = OrderStatus.pending;
  DateTime _orderDate = DateTime.now();
  DateTime? _deliveryDate;
  bool _loading = true;
  bool _saving = false;
  bool _newCustomerMode = true;

  bool get _isEdit => widget.order != null;

  @override
  void initState() {
    super.initState();
    final o = widget.order;
    _name = TextEditingController(text: o?.customerName ?? '');
    _phone = TextEditingController(text: o?.customerPhone ?? '');
    _address = TextEditingController();
    _garment = TextEditingController(text: o?.garmentType ?? Ur.garments.first);
    _instructions = TextEditingController(text: o?.instructions ?? '');
    _quantity = TextEditingController(text: '1');
    _rate = TextEditingController();
    _total = TextEditingController(
      text: o == null ? '' : _numText(o.totalAmount),
    );
    _advance = TextEditingController(
      text: o == null ? '' : _numText(o.advanceAmount),
    );

    if (o != null) {
      _customerId = o.customerId;
      _karigarId = o.karigarId;
      _status = o.status;
      _orderDate = o.orderDate;
      _deliveryDate = o.deliveryDate;
      _newCustomerMode = false;
      _applyMeasurements(o.measurements);
    }

    _rate.addListener(_recalcTotal);
    _quantity.addListener(_recalcTotal);
    _bootstrap();
  }

  String _numText(double v) =>
      v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  void _applyMeasurements(String? raw) {
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        for (final e in decoded.entries) {
          final ctrl = _measureCtrls[e.key.toString()];
          if (ctrl != null) ctrl.text = '${e.value}';
        }
        return;
      }
    } catch (_) {
      // Legacy free-text measurements → put into instructions note area if empty
      if (_instructions.text.isEmpty) {
        _instructions.text = raw;
      }
    }
  }

  String _encodeMeasurements() {
    final map = <String, String>{};
    for (final f in kMeasureFields) {
      final v = _measureCtrls[f.key]!.text.trim();
      if (v.isNotEmpty) map[f.key] = v;
    }
    if (map.isEmpty) return '';
    return jsonEncode(map);
  }

  String _measurementsReadable() {
    final parts = <String>[];
    for (final f in kMeasureFields) {
      final v = _measureCtrls[f.key]!.text.trim();
      if (v.isNotEmpty) parts.add('${f.label}: $v');
    }
    return parts.join('\n');
  }

  void _recalcTotal() {
    final qty = double.tryParse(_quantity.text.trim()) ?? 0;
    final rate = double.tryParse(_rate.text.trim()) ?? 0;
    if (qty > 0 && rate > 0) {
      final total = qty * rate;
      _total.text = _numText(total);
    }
  }

  Future<void> _bootstrap() async {
    try {
      final customers = await _customers.getAll();
      final karigars = await _karigars.getAll();
      if (!mounted) return;
      setState(() {
        _customerList = customers;
        _karigarList = karigars;
        if (_isEdit && _customerId != null) {
          final match = customers.where((c) => c.id == _customerId);
          if (match.isNotEmpty) {
            final c = match.first;
            _name.text = c.name;
            _phone.text = c.phone ?? '';
            _address.text = c.address ?? '';
          }
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _garment.dispose();
    _instructions.dispose();
    _quantity.dispose();
    _rate.dispose();
    _total.dispose();
    _advance.dispose();
    for (final c in _measureCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool delivery}) async {
    final initial = delivery ? (_deliveryDate ?? _orderDate) : _orderDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ur'),
    );
    if (picked == null) return;
    setState(() {
      if (delivery) {
        _deliveryDate = picked;
      } else {
        _orderDate = picked;
      }
    });
  }

  void _onSelectExisting(String? id) {
    setState(() {
      _customerId = id;
      _newCustomerMode = id == null;
      if (id != null) {
        final c = _customerList.firstWhere((e) => e.id == id);
        _name.text = c.name;
        _phone.text = c.phone ?? '';
        _address.text = c.address ?? '';
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      String customerId = _customerId ?? '';

      if (_newCustomerMode || customerId.isEmpty) {
        final created = await _customers.create(
          name: _name.text,
          phone: _phone.text,
          address: _address.text,
        );
        customerId = created.id;
      } else {
        final existing = _customerList.firstWhere((c) => c.id == customerId);
        await _customers.update(
          existing.copyWith(
            name: _name.text,
            phone: _phone.text,
            address: _address.text,
          ),
        );
      }

      final measureJson = _encodeMeasurements();
      final readable = _measurementsReadable();
      final stored = measureJson.isEmpty
          ? null
          : jsonEncode({
              ...jsonDecode(measureJson) as Map<String, dynamic>,
              '_label': readable,
            });

      final total = double.tryParse(_total.text.trim()) ?? 0;
      final advance = double.tryParse(_advance.text.trim()) ?? 0;

      if (_isEdit) {
        final wasDelivered = widget.order!.status == OrderStatus.delivered;
        final nowDelivered = _status == OrderStatus.delivered;
        await _orders.update(
          widget.order!.copyWith(
            customerId: customerId,
            karigarId: _karigarId,
            clearKarigar: _karigarId == null,
            garmentType: _garment.text,
            status: _status,
            orderDate: _orderDate,
            deliveryDate: _deliveryDate,
            clearDelivery: _deliveryDate == null,
            receivedAt: nowDelivered
                ? (widget.order!.receivedAt ?? DateTime.now())
                : null,
            clearReceived: !nowDelivered && wasDelivered,
            totalAmount: total,
            advanceAmount: advance,
            measurements: stored,
            instructions: _instructions.text,
          ),
        );
      } else {
        await _orders.create(
          customerId: customerId,
          karigarId: _karigarId,
          garmentType: _garment.text,
          status: _status,
          orderDate: _orderDate,
          deliveryDate: _deliveryDate,
          totalAmount: total,
          advanceAmount: advance,
          measurements: stored,
          instructions: _instructions.text,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'آرڈر اپڈیٹ ہو گیا' : 'نیا آرڈر محفوظ ہو گیا'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خرابی: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = (double.tryParse(_total.text) ?? 0) -
        (double.tryParse(_advance.text) ?? 0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? Ur.editOrder : Ur.newOrder),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
                  children: [
                    SectionCard(
                      title: 'گاہک کی تفصیل',
                      icon: Icons.person_outline,
                      child: Column(
                        children: [
                          if (_customerList.isNotEmpty) ...[
                            DropdownButtonFormField<String?>(
                              // ignore: deprecated_member_use
                              value: _newCustomerMode ? null : _customerId,
                              decoration: const InputDecoration(
                                labelText: 'موجودہ گاہک / نیا',
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('➕ نیا گاہک درج کریں'),
                                ),
                                ..._customerList.map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(
                                      '${c.name}${c.phone != null ? ' (${c.phone})' : ''}',
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: _onSelectExisting,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'گاہک کا نام *',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? Ur.required
                                : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: Ur.phone,
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _address,
                            decoration: const InputDecoration(
                              labelText: Ur.address,
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SectionCard(
                      title: 'آرڈر کی تفصیل',
                      icon: Icons.checkroom_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _garment,
                            decoration: const InputDecoration(
                              labelText: 'کپڑے کی قسم *',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? Ur.required
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: Ur.garments.map((g) {
                              final selected = _garment.text == g;
                              return ChoiceChip(
                                label: Text(g),
                                selected: selected,
                                onSelected: (_) =>
                                    setState(() => _garment.text = g),
                                selectedColor:
                                    AppColors.teal.withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? AppColors.teal
                                      : AppColors.ink,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<OrderStatus>(
                            // ignore: deprecated_member_use
                            value: _status,
                            decoration:
                                const InputDecoration(labelText: Ur.status),
                            items: OrderStatus.values
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.labelUr),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _status = v);
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String?>(
                            // ignore: deprecated_member_use
                            value: _karigarId,
                            decoration:
                                const InputDecoration(labelText: Ur.karigar),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(Ur.unassigned),
                              ),
                              ..._karigarList.map(
                                (k) => DropdownMenuItem(
                                  value: k.id,
                                  child: Text(k.name),
                                ),
                              ),
                            ],
                            onChanged: (v) => setState(() => _karigarId = v),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickDate(delivery: false),
                                  icon: const Icon(Icons.calendar_today,
                                      size: 16),
                                  label: Text(
                                    '${Ur.orderDate}\n${Formatters.date.format(_orderDate)}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickDate(delivery: true),
                                  icon: const Icon(Icons.event, size: 16),
                                  label: Text(
                                    _deliveryDate == null
                                        ? Ur.deliveryDate
                                        : '${Ur.deliveryDate}\n${Formatters.date.format(_deliveryDate!)}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_deliveryDate != null)
                            TextButton(
                              onPressed: () =>
                                  setState(() => _deliveryDate = null),
                              child: const Text(Ur.clearDelivery),
                            ),
                        ],
                      ),
                    ),
                    SectionCard(
                      title: Ur.measurements,
                      icon: Icons.straighten,
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: kMeasureFields.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.2,
                        ),
                        itemBuilder: (context, index) {
                          final f = kMeasureFields[index];
                          return TextFormField(
                            controller: _measureCtrls[f.key],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9./\-]'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: f.label,
                              isDense: true,
                            ),
                          );
                        },
                      ),
                    ),
                    SectionCard(
                      title: 'رقم / ادائیگی',
                      icon: Icons.payments_outlined,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _quantity,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: Ur.quantity,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _rate,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: Ur.rate,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _total,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: Ur.total,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _advance,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: Ur.advance,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${Ur.balance}: Rs ${_numText(balance < 0 ? 0 : balance)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.teal,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SectionCard(
                      title: Ur.instructions,
                      icon: Icons.notes_outlined,
                      child: TextFormField(
                        controller: _instructions,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'ڈیزائن، کپڑا، خاص نوٹ...',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? Ur.saving : Ur.saveOrder),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
