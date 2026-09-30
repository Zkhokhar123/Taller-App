import 'package:flutter/material.dart';

import '../../core/l10n/urdu.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/order_status_style.dart';
import '../../models/shop_settings.dart';
import '../../models/tailor_order.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/karigar_repository.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../widgets/common_widgets.dart';
import '../orders/order_form_screen.dart';
import '../orders/order_detail_screen.dart';
import '../karigars/karigars_screen.dart';
import '../tags/tags_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _orders = OrderRepository();
  final _customers = CustomerRepository();
  final _karigars = KarigarRepository();
  final _settings = SettingsRepository();

  bool _loading = true;
  ShopSettings _shop = const ShopSettings();
  int _customerCount = 0;
  int _karigarCount = 0;
  int _pending = 0;
  int _inProgress = 0;
  int _ready = 0;
  double _balance = 0;
  List<TailorOrder> _recent = [];

  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final shop = await _settings.load();
      final customers = await _customers.count();
      final karigars = await _karigars.count();
      final pending = await _orders.count(status: OrderStatus.pending);
      final inProgress = await _orders.count(status: OrderStatus.inProgress);
      final ready = await _orders.count(status: OrderStatus.ready);
      final balance = await _orders.pendingBalance();
      final recent = await _orders.getAll();
      if (!mounted) return;
      setState(() {
        _shop = shop;
        _customerCount = customers;
        _karigarCount = karigars;
        _pending = pending;
        _inProgress = inProgress;
        _ready = ready;
        _balance = balance;
        _recent = recent.take(8).toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(Ur.appName),
            Text(
              _shop.shopName.isEmpty ? Ur.appName : _shop.shopName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'کاریگر',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KarigarsScreen()),
              );
              _load();
            },
            icon: const Icon(Icons.handyman_outlined),
          ),
          IconButton(
            tooltip: 'ٹیگز',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TagsScreen()),
              );
              _load();
            },
            icon: const Icon(Icons.sell_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const OrderFormScreen()),
          );
          if (created == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text(Ur.newOrder),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'لوڈ نہیں ہوا',
                  subtitle: _error!,
                  actionLabel: Ur.retry,
                  onAction: _load,
                )
              : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.navy, Color(0xFF134E4A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          Ur.offlineShop,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'گاہک، آرڈر اور سلپ — سب آپ کے فون میں۔',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'باقی رقم: ${Formatters.money(_balance, symbol: _shop.currencySymbol)}',
                          style: const TextStyle(
                            color: AppColors.tealLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      StatCard(
                        label: 'گاہک',
                        value: '$_customerCount',
                        icon: Icons.people_alt_outlined,
                        color: AppColors.teal,
                      ),
                      StatCard(
                        label: 'کاریگر',
                        value: '$_karigarCount',
                        icon: Icons.handyman_outlined,
                        color: AppColors.navy,
                      ),
                      StatCard(
                        label: 'زیرِ التوا',
                        value: '$_pending',
                        icon: Icons.schedule,
                        color: AppColors.warning,
                      ),
                      StatCard(
                        label: 'جاری / تیار',
                        value: '$_inProgress / $_ready',
                        icon: Icons.checkroom_outlined,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    Ur.recentOrders,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_recent.isEmpty)
                    const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: Ur.noOrders,
                      subtitle: 'پہلا آرڈر سلپ بنا کر شروع کریں۔',
                    )
                  else
                    ..._recent.map(
                      (o) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          title: Text(
                            '${Formatters.orderNo(o.orderNo)} · ${o.garmentType}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${o.customerName ?? 'Customer'} · ${Formatters.money(o.totalAmount, symbol: _shop.currencySymbol)}',
                          ),
                          trailing: StatusChip(
                            label: o.status.labelUr,
                            color: orderStatusColor(o.status),
                          ),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(orderId: o.id),
                              ),
                            );
                            _load();
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
