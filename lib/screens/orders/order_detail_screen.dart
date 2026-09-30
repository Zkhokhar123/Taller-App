import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/order_status_style.dart';
import '../../models/shop_settings.dart';
import '../../models/tag_item.dart';
import '../../models/tailor_order.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/tag_repository.dart';
import '../../services/slip_service.dart';
import '../../widgets/common_widgets.dart';
import 'order_form_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _orders = OrderRepository();
  final _tags = TagRepository();

  TailorOrder? _order;
  ShopSettings _shop = const ShopSettings();
  List<TagItem> _allTags = [];
  bool _loading = true;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final order = await _orders.getById(widget.orderId);
      final shop = await SlipService.resolveShop();
      final tags = await _tags.getAll();
      if (!mounted) return;
      setState(() {
        _order = order;
        _shop = shop;
        _allTags = tags;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('آرڈر حذف کریں؟'),
        content: const Text('یہ آرڈر سلپ مستقل طور پر ہٹ جائے گی۔'),
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
    if (ok != true || _order == null) return;
    await _orders.delete(_order!.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _print({required bool karigar}) async {
    final order = _order;
    if (order == null) return;
    setState(() => _printing = true);
    try {
      final shop = await SlipService.resolveShop();
      await SlipService.printOrderSlip(
        order: order,
        shop: shop,
        karigarCopy: karigar,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('پرنٹ خرابی: $e')),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _share({required bool karigar}) async {
    final order = _order;
    if (order == null) return;
    setState(() => _printing = true);
    try {
      final shop = await SlipService.resolveShop();
      await SlipService.shareOrderSlip(
        order: order,
        shop: shop,
        karigarCopy: karigar,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('شیئر خرابی: $e')),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _markReceived() async {
    final order = _order;
    if (order == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('گاہک نے آرڈر لے لیا؟'),
        content: Text(
          'آرڈر ${Formatters.orderNo(order.orderNo)} — ${order.customerName ?? "گاہک"} کو دے دیا گیا؟\n\nاس کے بعد سٹیٹس "گاہک کو مل گیا" ہو جائے گا اور تاریخ محفوظ ہوگی۔',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ابھی نہیں'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ہاں، مل گیا'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final updated = await _orders.markReceivedByCustomer(order.id);
      if (!mounted) return;
      setState(() => _order = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ گاہک کو دے دیا گیا — ${Formatters.dateTime.format(updated.receivedAt!)}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final measureText = SlipService.measurementsText(order?.measurements);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          order == null ? 'آرڈر' : Formatters.orderNo(order.orderNo),
        ),
        actions: [
          if (order != null)
            IconButton(
              onPressed: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => OrderFormScreen(order: order),
                  ),
                );
                if (changed == true) _load();
              },
              icon: const Icon(Icons.edit_outlined),
            ),
          if (order != null)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? const EmptyState(
                  icon: Icons.error_outline,
                  title: 'آرڈر نہیں ملا',
                  subtitle: 'شاید حذف ہو چکا ہو۔',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    // Live shop header preview (same as slip top)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.navy, Color(0xFF134E4A)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _shop.shopName.isEmpty
                                ? 'دکان کا نام رجسٹر نہیں'
                                : _shop.shopName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (_shop.phone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _shop.phone,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                          if (_shop.address.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _shop.address,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (order.isReceivedByCustomer)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified,
                              color: AppColors.success,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'گاہک نے آرڈر وصول کر لیا',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.success,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (order.receivedAt != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'تاریخ: ${Formatters.dateTime.format(order.receivedAt!)}',
                                      style: const TextStyle(
                                        color: AppColors.ink,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ElevatedButton.icon(
                          onPressed: _markReceived,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                          ),
                          icon: const Icon(Icons.handshake_outlined),
                          label: const Text(
                            'گاہک نے وصول کر لیا ✓',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    order.garmentType,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ),
                                StatusChip(
                                  label: order.status.labelUr,
                                  color: orderStatusColor(order.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _info('گاہک', order.customerName ?? '-'),
                            if ((order.customerPhone ?? '').isNotEmpty)
                              _info('فون', order.customerPhone!),
                            _info(
                              'آرڈر تاریخ',
                              Formatters.date.format(order.orderDate),
                            ),
                            if (order.deliveryDate != null)
                              _info(
                                'ڈیلیوری',
                                Formatters.date.format(order.deliveryDate!),
                              ),
                            _info(
                              'کاریگر',
                              order.karigarName ?? 'غیر مقرر',
                            ),
                            if (order.receivedAt != null)
                              _info(
                                'وصول تاریخ',
                                Formatters.dateTime.format(order.receivedAt!),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _moneyRow(
                              'کل رقم',
                              Formatters.money(
                                order.totalAmount,
                                symbol: _shop.currencySymbol,
                              ),
                            ),
                            _moneyRow(
                              'ایڈوانس',
                              Formatters.money(
                                order.advanceAmount,
                                symbol: _shop.currencySymbol,
                              ),
                            ),
                            const Divider(height: 20),
                            _moneyRow(
                              'باقی رقم',
                              Formatters.money(
                                order.balance,
                                symbol: _shop.currencySymbol,
                              ),
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (measureText.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          title: const Text(
                            'ناپ',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(measureText),
                          ),
                        ),
                      ),
                    ],
                    if ((order.instructions ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          title: const Text(
                            'ہدایات',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(order.instructions!),
                          ),
                        ),
                      ),
                    ],
                    if (order.tagIds.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: order.tagIds.map((id) {
                          final tag = _allTags.where((t) => t.id == id);
                          if (tag.isEmpty) return const SizedBox.shrink();
                          final t = tag.first;
                          return Chip(
                            label: Text(t.name),
                            backgroundColor: t.color.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: t.color,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'پرنٹ / شیئر سلپ',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'سلپ کے اوپر دکان کا نام: ${_shop.shopName.isEmpty ? "—" : _shop.shopName}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_printing)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      ElevatedButton.icon(
                        onPressed: () => _print(karigar: false),
                        icon: const Icon(Icons.print),
                        label: const Text('آرڈر سلپ پرنٹ'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _share(karigar: false),
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('آرڈر سلپ شیئر'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _print(karigar: true),
                        icon: const Icon(Icons.handyman_outlined),
                        label: const Text('کاریگر سلپ پرنٹ'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _share(karigar: true),
                        icon: const Icon(Icons.ios_share),
                        label: const Text('کاریگر سلپ شیئر'),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: bold ? AppColors.teal : AppColors.ink,
          ),
        ),
      ],
    );
  }
}
