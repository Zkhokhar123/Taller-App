import 'dart:convert';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/l10n/urdu.dart';
import '../core/utils/formatters.dart';
import '../models/shop_settings.dart';
import '../models/tailor_order.dart';
import '../repositories/auth_repository.dart';
import '../repositories/settings_repository.dart';

/// 58mm thermal Urdu slips — shop name always from registered account.
class SlipService {
  /// ~58mm roll width
  static const thermalWidth = PdfPageFormat(165, double.infinity, marginAll: 10);

  static Future<ShopSettings> resolveShop() async {
    final account = await AuthRepository().currentAccount();
    final settings = await SettingsRepository().load();
    if (account != null) {
      return ShopSettings(
        shopName: account.shopName,
        phone: account.phone,
        address: account.address,
        currencySymbol: settings.currencySymbol.isEmpty
            ? 'Rs'
            : settings.currencySymbol,
      );
    }
    return settings;
  }

  static Future<void> printOrderSlip({
    required TailorOrder order,
    ShopSettings? shop,
    bool karigarCopy = false,
  }) async {
    final resolved = shop ?? await resolveShop();
    final doc = await _buildDoc(
      order: order,
      shop: resolved,
      karigarCopy: karigarCopy,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: karigarCopy
          ? 'karigar-slip-${order.orderNo}'
          : 'order-slip-${order.orderNo}',
    );
  }

  static Future<void> shareOrderSlip({
    required TailorOrder order,
    ShopSettings? shop,
    bool karigarCopy = false,
  }) async {
    final resolved = shop ?? await resolveShop();
    final doc = await _buildDoc(
      order: order,
      shop: resolved,
      karigarCopy: karigarCopy,
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: karigarCopy
          ? 'karigar_slip_${order.orderNo}.pdf'
          : 'order_slip_${order.orderNo}.pdf',
    );
  }

  static String measurementsText(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final parts = <String>[];
        for (final f in kMeasureFields) {
          final v = decoded[f.key];
          if (v != null && '$v'.trim().isNotEmpty) {
            parts.add('${f.label}: $v');
          }
        }
        if (parts.isNotEmpty) return parts.join('\n');
        final label = decoded['_label'];
        if (label != null && '$label'.trim().isNotEmpty) return '$label';
      }
    } catch (_) {}
    // Hide raw JSON from slips
    if (raw.trim().startsWith('{')) return '';
    return raw;
  }

  static Future<pw.Document> _buildDoc({
    required TailorOrder order,
    required ShopSettings shop,
    required bool karigarCopy,
  }) async {
    final doc = pw.Document();
    final measureText = measurementsText(order.measurements);
    final shopTitle =
        shop.shopName.trim().isEmpty ? Ur.appName : shop.shopName.trim();

    pw.Font? font;
    pw.Font? fontBold;
    try {
      font = await PdfGoogleFonts.notoNaskhArabicRegular();
      fontBold = await PdfGoogleFonts.notoNaskhArabicBold();
    } catch (_) {
      try {
        font = await PdfGoogleFonts.notoSansRegular();
        fontBold = await PdfGoogleFonts.notoSansBold();
      } catch (_) {}
    }

    final theme = font != null
        ? pw.ThemeData.withFont(base: font, bold: fontBold ?? font)
        : pw.ThemeData.base();

    doc.addPage(
      pw.Page(
        pageFormat: thermalWidth,
        theme: theme,
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ===== Shop header (registered name) =====
                pw.Text(
                  shopTitle,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (shop.phone.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'فون: ${shop.phone}',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
                if (shop.address.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    shop.address,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
                pw.SizedBox(height: 6),
                pw.Container(height: 1, color: PdfColors.black),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  color: PdfColors.grey300,
                  child: pw.Text(
                    karigarCopy ? 'کاریگر سلپ' : 'آرڈر سلپ / رسید',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                _row('آرڈر نمبر', Formatters.orderNo(order.orderNo)),
                _row('تاریخ', Formatters.date.format(order.orderDate)),
                if (order.deliveryDate != null)
                  _row(
                    'ڈیلیوری',
                    Formatters.date.format(order.deliveryDate!),
                  ),
                _row('گاہک', order.customerName ?? '-'),
                if ((order.customerPhone ?? '').isNotEmpty)
                  _row('گاہک فون', order.customerPhone!),
                _row('کپڑا', order.garmentType),
                if (!karigarCopy) _row('حالت', order.status.labelUr),
                _row(
                  'کاریگر',
                  (order.karigarName ?? '').isEmpty
                      ? 'غیر مقرر'
                      : order.karigarName!,
                ),
                pw.SizedBox(height: 6),
                pw.Container(height: 1, color: PdfColors.black),
                pw.SizedBox(height: 4),
                if (measureText.isNotEmpty) ...[
                  pw.Text(
                    'ناپ کی تفصیل',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(measureText, style: const pw.TextStyle(fontSize: 8)),
                  pw.SizedBox(height: 6),
                ],
                if ((order.instructions ?? '').isNotEmpty) ...[
                  pw.Text(
                    'خصوصی ہدایات',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    order.instructions!,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.SizedBox(height: 6),
                ],
                if (!karigarCopy) ...[
                  pw.Container(height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'رقم کی تفصیل',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  _row(
                    'کل رقم',
                    Formatters.money(
                      order.totalAmount,
                      symbol: shop.currencySymbol,
                    ),
                  ),
                  _row(
                    'ایڈوانس',
                    Formatters.money(
                      order.advanceAmount,
                      symbol: shop.currencySymbol,
                    ),
                  ),
                  _row(
                    'باقی رقم',
                    Formatters.money(
                      order.balance,
                      symbol: shop.currencySymbol,
                    ),
                  ),
                ] else ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'نوٹ: یہ سلپ صرف کاریگر کے کام کے لیے ہے۔',
                    style: const pw.TextStyle(fontSize: 7),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
                pw.SizedBox(height: 10),
                pw.Container(height: 1, color: PdfColors.black),
                pw.SizedBox(height: 6),
                pw.Text(
                  'شکریہ — $shopTitle',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    return doc;
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 55,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
          pw.Text(': ', style: const pw.TextStyle(fontSize: 8)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
