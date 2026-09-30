import 'package:flutter/material.dart';

import '../../core/l10n/urdu.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/order_status_style.dart';
import '../../models/shop_settings.dart';
import '../../models/tailor_order.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../widgets/common_widgets.dart';
import 'order_detail_screen.dart';
import 'order_form_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _repo = OrderRepository();
  final _settingsRepo = SettingsRepository();
  final _search = TextEditingController();
  OrderStatus? _filter;
  List<TailorOrder> _items = [];
  ShopSettings _shop = const ShopSettings();
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
      final shop = await _settingsRepo.load();
      final items = await _repo.getAll(query: _search.text, status: _filter);
      if (!mounted) return;
      setState(() {
        _shop = shop;
        _items = items;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Ur.orders)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const OrderFormScreen()),
          );
          if (created == true) _load();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: Ur.searchOrder,
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => _load(),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _StatusFilterChip(
                    label: 'سب',
                    color: AppColors.navy,
                    selected: _filter == null,
                    onTap: () {
                      setState(() => _filter = null);
                      _load();
                    },
                  ),
                ),
                ...OrderStatus.values.map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _StatusFilterChip(
                      label: s.labelUr,
                      color: orderStatusColor(s),
                      selected: _filter == s,
                      onTap: () {
                        setState(() => _filter = s);
                        _load();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: Ur.noOrders,
                        subtitle: 'نیا آرڈر سلپ بنائیں۔',
                        actionLabel: Ur.newOrder,
                        onAction: () async {
                          final created = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => const OrderFormScreen(),
                            ),
                          );
                          if (created == true) _load();
                        },
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final o = _items[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                title: Text(
                                  '${Formatters.orderNo(o.orderNo)} · ${o.garmentType}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(o.customerName ?? 'گاہک'),
                                      const SizedBox(height: 2),
                                      Text(
                                        o.isReceivedByCustomer &&
                                                o.receivedAt != null
                                            ? 'وصول: ${Formatters.dateTime.format(o.receivedAt!)}'
                                            : '${Formatters.date.format(o.orderDate)} · ${Formatters.money(o.totalAmount, symbol: _shop.currencySymbol)}',
                                        style: TextStyle(
                                          color: o.isReceivedByCustomer
                                              ? AppColors.success
                                              : AppColors.muted,
                                          fontSize: 12,
                                          fontWeight: o.isReceivedByCustomer
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: StatusChip(
                                  label: o.status.labelUr,
                                  color: orderStatusColor(o.status),
                                ),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          OrderDetailScreen(orderId: o.id),
                                    ),
                                  );
                                  _load();
                                },
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

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusFilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: color,
              width: selected ? 2 : 1.4,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
