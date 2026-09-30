import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/tailor_order.dart';

Color orderStatusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return AppColors.warning;
    case OrderStatus.inProgress:
      return const Color(0xFF2563EB);
    case OrderStatus.ready:
      return AppColors.teal;
    case OrderStatus.delivered:
      return AppColors.success;
    case OrderStatus.cancelled:
      return AppColors.danger;
  }
}
