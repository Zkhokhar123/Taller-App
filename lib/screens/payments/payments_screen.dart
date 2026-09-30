import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/payment_record.dart';
import '../../repositories/payment_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../widgets/common_widgets.dart';
import '../orders/order_detail_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _payments = PaymentRepository();
  final _settings = SettingsRepository();

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  MonthPaymentSummary? _summary;
  String _currency = 'Rs';
  bool _loading = true;
  int _tab = 0; // 0 = received, 1 = pending

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final shop = await _settings.load();
      final summary = await _payments.monthSummary(_month);
      if (!mounted) return;
      setState(() {
        _currency = shop.currencySymbol.isEmpty ? 'Rs' : shop.currencySymbol;
        _summary = summary;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
    _load();
  }

  String get _monthLabel {
    try {
      return DateFormat('MMMM yyyy', 'ur').format(_month);
    } catch (_) {
      return DateFormat('MMM yyyy').format(_month);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(title: const Text('ادائیگیاں')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _shiftMonth(-1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                      Expanded(
                        child: Text(
                          _monthLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _shiftMonth(1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryTile(
                          title: 'اس مہینے وصول',
                          value: Formatters.money(
                            summary?.receivedThisMonth ?? 0,
                            symbol: _currency,
                          ),
                          color: AppColors.success,
                          icon: Icons.south_west,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryTile(
                          title: 'باقی رقم',
                          value: Formatters.money(
                            summary?.outstandingBalance ?? 0,
                            symbol: _currency,
                          ),
                          color: AppColors.warning,
                          icon: Icons.pending_actions,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'بقایا سوٹ: ${summary?.pendingSuits ?? 0}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('تاریخ وار وصولی'),
                          selected: _tab == 0,
                          selectedColor: AppColors.teal.withValues(alpha: 0.25),
                          onSelected: (_) => setState(() => _tab = 0),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _tab == 0 ? AppColors.teal : AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('سوٹ بقایا'),
                          selected: _tab == 1,
                          selectedColor:
                              AppColors.warning.withValues(alpha: 0.25),
                          onSelected: (_) => setState(() => _tab = 1),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color:
                                _tab == 1 ? AppColors.warning : AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_tab == 0) ..._buildPayments(summary) else ..._buildPending(summary),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildPayments(MonthPaymentSummary? summary) {
    final items = summary?.payments ?? [];
    if (items.isEmpty) {
      return [
        const EmptyState(
          icon: Icons.payments_outlined,
          title: 'اس مہینے کوئی ادائیگی نہیں',
          subtitle: 'آرڈر پر ایڈوانس یا وصولی یہاں دکھے گی۔',
        ),
      ];
    }

    // Group by date
    final groups = <String, List<PaymentRecord>>{};
    for (final p in items) {
      final key = Formatters.date.format(p.paidAt);
      groups.putIfAbsent(key, () => []).add(p);
    }

    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      final dayTotal =
          entry.value.fold<double>(0, (s, p) => s + p.amount);
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 6),
          child: Row(
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const Spacer(),
              Text(
                Formatters.money(dayTotal, symbol: _currency),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      );
      for (final p in entry.value) {
        widgets.add(
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.success.withValues(alpha: 0.15),
                foregroundColor: AppColors.success,
                child: const Icon(Icons.check, size: 20),
              ),
              title: Text(
                '${Formatters.orderNo(p.orderNo ?? 0)} · ${p.garmentType ?? 'سوٹ'}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${p.customerName ?? 'گاہک'} · ${p.typeUr}\n${Formatters.dateTime.format(p.paidAt)}',
              ),
              isThreeLine: true,
              trailing: Text(
                Formatters.money(p.amount, symbol: _currency),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(orderId: p.orderId),
                  ),
                );
                _load();
              },
            ),
          ),
        );
      }
    }
    return widgets;
  }

  List<Widget> _buildPending(MonthPaymentSummary? summary) {
    final items = summary?.pendingOrders ?? [];
    if (items.isEmpty) {
      return [
        const EmptyState(
          icon: Icons.verified_outlined,
          title: 'کوئی بقایا نہیں',
          subtitle: 'تمام سوٹوں کی ادائیگی کلیئر ہے۔',
        ),
      ];
    }

    return items
        .map(
          (o) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                foregroundColor: AppColors.warning,
                child: const Icon(Icons.attach_money, size: 20),
              ),
              title: Text(
                '${Formatters.orderNo(o.orderNo)} · ${o.garmentType}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${o.customerName}\nکل: ${Formatters.money(o.totalAmount, symbol: _currency)} · ادا: ${Formatters.money(o.paidAmount, symbol: _currency)}\nتاریخ: ${Formatters.date.format(o.orderDate)}',
              ),
              isThreeLine: true,
              trailing: Text(
                Formatters.money(o.balance, symbol: _currency),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.warning,
                ),
              ),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(orderId: o.orderId),
                  ),
                );
                _load();
              },
            ),
          ),
        )
        .toList();
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryTile({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
