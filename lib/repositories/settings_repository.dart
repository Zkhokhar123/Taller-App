import 'package:shared_preferences/shared_preferences.dart';

import '../models/shop_settings.dart';

class SettingsRepository {
  static const _shopName = 'shop_name';
  static const _phone = 'shop_phone';
  static const _address = 'shop_address';
  static const _currency = 'currency_symbol';

  Future<ShopSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ShopSettings(
      shopName: prefs.getString(_shopName) ?? '',
      phone: prefs.getString(_phone) ?? '',
      address: prefs.getString(_address) ?? '',
      currencySymbol: prefs.getString(_currency) ?? 'Rs',
    );
  }

  Future<void> save(ShopSettings settings) async {
    if (settings.shopName.trim().isEmpty ||
        settings.phone.trim().isEmpty ||
        settings.address.trim().isEmpty) {
      throw Exception('دکان کا نام، فون اور پتہ ضروری ہیں');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_shopName, settings.shopName.trim());
    await prefs.setString(_phone, settings.phone.trim());
    await prefs.setString(_address, settings.address.trim());
    await prefs.setString(
      _currency,
      settings.currencySymbol.trim().isEmpty
          ? 'Rs'
          : settings.currencySymbol.trim(),
    );
  }
}