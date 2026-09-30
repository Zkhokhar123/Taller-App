import 'package:flutter_test/flutter_test.dart';

import 'package:tallermaster/models/tailor_order.dart';

void main() {
  test('Order balance calculates correctly', () {
    final order = TailorOrder(
      id: '1',
      orderNo: 1001,
      customerId: 'c1',
      garmentType: 'Kurta',
      status: OrderStatus.pending,
      orderDate: DateTime(2026, 1, 1),
      totalAmount: 5000,
      advanceAmount: 1500,
      createdAt: DateTime(2026, 1, 1),
    );
    expect(order.balance, 3500);
  });
}
