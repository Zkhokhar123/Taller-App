import 'package:intl/intl.dart';

class Formatters {
  static final date = DateFormat('dd MMM yyyy');
  static final dateTime = DateFormat('dd MMM yyyy, hh:mm a');

  static String money(double amount, {String symbol = 'Rs'}) {
    final formatted = NumberFormat('#,##0.##').format(amount);
    return '$symbol $formatted';
  }

  static String orderNo(int no) => '#$no';
}
