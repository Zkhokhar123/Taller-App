import 'package:flutter/material.dart';

import '../../core/l10n/urdu.dart';
import '../../core/theme/app_theme.dart';
import '../../models/shop_settings.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/settings_repository.dart';
import '../auth/login_screen.dart';
import '../tags/tags_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsRepo = SettingsRepository();
  final _auth = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _shopName;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _currency;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _shopName = TextEditingController();
    _phone = TextEditingController();
    _address = TextEditingController();
    _currency = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    try {
      // Prefer live account data, fallback to settings cache.
      final account = await _auth.currentAccount();
      final settings = await _settingsRepo.load();
      if (!mounted) return;
      setState(() {
        _shopName.text = account?.shopName ?? settings.shopName;
        _phone.text = account?.phone ?? settings.phone;
        _address.text = account?.address ?? settings.address;
        _currency.text = settings.currencySymbol;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _shopName.dispose();
    _phone.dispose();
    _address.dispose();
    _currency.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _auth.updateProfile(
        shopName: _shopName.text,
        phone: _phone.text,
        address: _address.text,
      );
      await _settingsRepo.save(
        ShopSettings(
          shopName: _shopName.text.trim(),
          phone: _phone.text.trim(),
          address: _address.text.trim(),
          currencySymbol: _currency.text.trim().isEmpty ? 'Rs' : _currency.text,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('دکان کی تفصیل محفوظ ہو گئی')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('لاگ آؤٹ؟'),
        content: const Text('کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('نہیں'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ہاں'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Ur.settings)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.cloud_off, color: AppColors.teal),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'مکمل آف لائن موبائل ایپ۔ تمام ڈیٹا اسی فون میں محفوظ ہے۔',
                            style: TextStyle(height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'دکان کا پروفائل',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _shopName,
                    decoration: const InputDecoration(
                      labelText: 'دکان کا نام *',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'ضروری ہے' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'فون نمبر *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'ضروری ہے' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(labelText: 'پتہ *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'ضروری ہے' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _currency,
                    decoration: const InputDecoration(
                      labelText: 'کرنسی',
                      hintText: 'Rs',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'محفوظ ہو رہا ہے...' : 'محفوظ کریں'),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFECFDF5),
                      foregroundColor: AppColors.teal,
                      child: Icon(Icons.sell_outlined),
                    ),
                    title: const Text(
                      'کسٹم ٹیگز',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('فوری، VIP، الٹر وغیرہ'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TagsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 28),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: AppColors.danger),
                    label: const Text(
                      'لاگ آؤٹ',
                      style: TextStyle(color: AppColors.danger),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ٹیلر ماسٹر v1.0.0\nآف لائن درزی شاپ مینیجر — گاہک، آرڈر سلپ، کاریگر سلپ، ٹیگز اور تھرمل پرنٹ۔',
                    style: TextStyle(color: AppColors.muted, height: 1.45),
                  ),
                ],
              ),
            ),
    );
  }
}
