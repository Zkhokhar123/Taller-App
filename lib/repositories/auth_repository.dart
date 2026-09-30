import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../models/shop_account.dart';
import '../models/shop_settings.dart';
import 'settings_repository.dart';

class AuthRepository {
  static const _loggedInKey = 'auth_logged_in';
  static const _accountIdKey = 'auth_account_id';

  final _uuid = const Uuid();
  final _settings = SettingsRepository();

  String hashPassword(String password) {
    final bytes = utf8.encode('taller_master_salt::$password');
    return sha256.convert(bytes).toString();
  }

  Future<bool> hasRegisteredAccount() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM shop_account');
    return ((rows.first['c'] as int?) ?? 0) > 0;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  Future<ShopAccount?> currentAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_accountIdKey);
    if (id == null) return null;
    return getById(id);
  }

  Future<ShopAccount?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'shop_account',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ShopAccount.fromMap(rows.first);
  }

  Future<ShopAccount?> getByPhone(String phone) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'shop_account',
      where: 'phone = ?',
      whereArgs: [phone.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ShopAccount.fromMap(rows.first);
  }

  /// Register fails if shopName / phone / address / password missing.
  Future<ShopAccount> register({
    required String shopName,
    required String phone,
    required String address,
    required String password,
  }) async {
    final name = shopName.trim();
    final ph = phone.trim();
    final addr = address.trim();
    final pass = password.trim();

    if (name.isEmpty || ph.isEmpty || addr.isEmpty || pass.isEmpty) {
      throw Exception(
        'دکان کا نام، فون نمبر اور پتہ ضروری ہیں — ان کے بغیر اکاؤنٹ نہیں بنے گا',
      );
    }
    if (pass.length < 4) {
      throw Exception('پاس ورڈ کم از کم 4 ہندسوں/حروف کا ہو');
    }

    final existing = await getByPhone(ph);
    if (existing != null) {
      throw Exception('اس فون نمبر سے پہلے سے اکاؤنٹ موجود ہے');
    }

    final already = await hasRegisteredAccount();
    if (already) {
      throw Exception('ایک دکان پہلے سے رجسٹر ہے — براہ کرم لاگ اِن کریں');
    }

    final account = ShopAccount(
      id: _uuid.v4(),
      shopName: name,
      phone: ph,
      address: addr,
      passwordHash: hashPassword(pass),
      createdAt: DateTime.now(),
    );

    final db = await AppDatabase.instance.database;
    await db.insert('shop_account', account.toMap());

    final current = await _settings.load();
    await _settings.save(
      ShopSettings(
        shopName: account.shopName,
        phone: account.phone,
        address: account.address,
        currencySymbol: current.currencySymbol,
      ),
    );

    await _setSession(account.id);
    return account;
  }

  Future<ShopAccount> login({
    required String phone,
    required String password,
  }) async {
    final ph = phone.trim();
    final pass = password.trim();
    if (ph.isEmpty || pass.isEmpty) {
      throw Exception('فون نمبر اور پاس ورڈ درج کریں');
    }

    final account = await getByPhone(ph);
    if (account == null) {
      throw Exception('اکاؤنٹ نہیں ملا — پہلے رجسٹر کریں');
    }
    if (account.passwordHash != hashPassword(pass)) {
      throw Exception('غلط پاس ورڈ');
    }

    final current = await _settings.load();
    await _settings.save(
      ShopSettings(
        shopName: account.shopName,
        phone: account.phone,
        address: account.address,
        currencySymbol: current.currencySymbol,
      ),
    );
    await _setSession(account.id);
    return account;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
    await prefs.remove(_accountIdKey);
  }

  Future<void> updateProfile({
    required String shopName,
    required String phone,
    required String address,
  }) async {
    final account = await currentAccount();
    if (account == null) return;

    final name = shopName.trim();
    final ph = phone.trim();
    final addr = address.trim();
    if (name.isEmpty || ph.isEmpty || addr.isEmpty) {
      throw Exception('دکان کا نام، فون اور پتہ خالی نہیں ہو سکتے');
    }

    final db = await AppDatabase.instance.database;
    await db.update(
      'shop_account',
      {
        'shop_name': name,
        'phone': ph,
        'address': addr,
      },
      where: 'id = ?',
      whereArgs: [account.id],
    );

    final current = await _settings.load();
    await _settings.save(
      ShopSettings(
        shopName: name,
        phone: ph,
        address: addr,
        currencySymbol: current.currencySymbol,
      ),
    );
  }

  Future<void> _setSession(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_accountIdKey, accountId);
  }
}
