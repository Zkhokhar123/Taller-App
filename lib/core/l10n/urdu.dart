import 'package:flutter/material.dart';

/// App-wide Urdu labels for tailor shop UI.
class Ur {
  static const appName = 'ٹیلر ماسٹر';
  static const home = 'ہوم';
  static const orders = 'آرڈرز';
  static const customers = 'گاہک';
  static const karigar = 'کاریگر';
  static const settings = 'سیٹنگز';
  static const tags = 'ٹیگز';
  static const newOrder = 'نیا آرڈر';
  static const editOrder = 'آرڈر ترمیم';
  static const saveOrder = 'آرڈر محفوظ کریں';
  static const saving = 'محفوظ ہو رہا ہے...';
  static const customer = 'گاہک';
  static const selectCustomer = 'گاہک منتخب کریں';
  static const addCustomer = 'نیا گاہک';
  static const customerName = 'گاہک کا نام';
  static const phone = 'فون نمبر';
  static const address = 'پتہ';
  static const garment = 'کپڑے کی قسم';
  static const status = 'حالت';
  static const orderDate = 'آرڈر کی تاریخ';
  static const deliveryDate = 'ڈیلیوری تاریخ';
  static const clearDelivery = 'ڈیلیوری تاریخ ہٹائیں';
  static const measurements = 'ناپ (Measurements)';
  static const instructions = 'خصوصی ہدایات';
  static const total = 'کل رقم';
  static const advance = 'ایڈوانس';
  static const balance = 'باقی رقم';
  static const quantity = 'تعداد';
  static const rate = 'ریٹ';
  static const notes = 'نوٹس';
  static const required = 'ضروری ہے';
  static const unassigned = 'غیر مقرر';
  static const retry = 'دوبارہ کوشش';
  static const recentOrders = 'حالیہ آرڈرز';
  static const offlineShop = 'آف لائن درزی دکان';
  static const searchOrder = 'آرڈر / گاہک تلاش کریں';
  static const searchCustomer = 'نام یا فون تلاش کریں';
  static const noOrders = 'ابھی کوئی آرڈر نہیں';
  static const noCustomers = 'ابھی کوئی گاہک نہیں';
  static const printOrderSlip = 'آرڈر سلپ پرنٹ';
  static const printKarigarSlip = 'کاریگر سلپ پرنٹ';
  static const shareOrderSlip = 'آرڈر سلپ شیئر';
  static const shareKarigarSlip = 'کاریگر سلپ شیئر';

  static const pending = 'زیرِ التوا';
  static const inProgress = 'کام جاری';
  static const ready = 'تیار';
  static const delivered = 'ڈیلیور';
  static const cancelled = 'منسوخ';

  static const garments = <String>[
    'شلوار قمیض',
    'کرتہ',
    'ویسٹ کوٹ',
    'کوٹ',
    'پینٹ',
    'شرٹ',
    'بلاؤز',
    'لہنگا',
    'عباہ',
    'الٹر',
  ];
}

class MeasureField {
  final String key;
  final String label;

  const MeasureField(this.key, this.label);
}

/// Classic Pakistani tailor slip measurement fields (Urdu).
const kMeasureFields = <MeasureField>[
  MeasureField('length', 'لمبائی'),
  MeasureField('shoulder', 'تیرا / کندھا'),
  MeasureField('sleeve', 'بازو'),
  MeasureField('collar', 'کالر'),
  MeasureField('chest', 'چھاتی'),
  MeasureField('waist', 'کمر'),
  MeasureField('hip', 'ہپ'),
  MeasureField('shalwar', 'شلوار'),
  MeasureField('pancha', 'پاؤنچہ'),
  MeasureField('ghera', 'گھیرا'),
  MeasureField('armhole', 'بازو ہول'),
  MeasureField('cuff', 'کف'),
];

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: const Color(0xFF0F766E)),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0B1F33),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
