import 'package:flutter/material.dart';

import '../../core/l10n/urdu.dart';
import '../../core/theme/app_theme.dart';
import '../../repositories/auth_repository.dart';
import '../home_shell.dart';

class RegisterScreen extends StatefulWidget {
  final bool isFirstLaunch;

  const RegisterScreen({super.key, this.isFirstLaunch = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthRepository();
  final _shopName = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  bool get _canRegister {
    return _shopName.text.trim().isNotEmpty &&
        _phone.text.trim().isNotEmpty &&
        _address.text.trim().isNotEmpty &&
        _password.text.trim().length >= 4 &&
        _confirm.text.trim() == _password.text.trim();
  }

  @override
  void initState() {
    super.initState();
    for (final c in [_shopName, _phone, _address, _password, _confirm]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _shopName.dispose();
    _phone.dispose();
    _address.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canRegister) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'دکان کا نام، فون نمبر اور پتہ ضروری ہیں — ان کے بغیر رجسٹر نہیں ہوگا',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.register(
        shopName: _shopName.text,
        phone: _phone.text,
        address: _address.text,
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isFirstLaunch
          ? AppBar(
              title: const Text('نیا اکاؤنٹ'),
              backgroundColor: AppColors.navy,
              automaticallyImplyLeading: false,
            )
          : AppBar(
              title: const Text('نیا اکاؤنٹ'),
              backgroundColor: AppColors.navy,
            ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5F3), AppColors.surface],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.teal),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'رجسٹریشن تبھی مکمل ہوگی جب دکان کا نام، فون نمبر اور پتہ سب بھرے ہوں۔',
                        style: TextStyle(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _shopName,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'دکان کا نام *',
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'دکان کا نام ضروری ہے'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'فون نمبر *',
                          prefixIcon: Icon(Icons.phone_android),
                          hintText: '03xxxxxxxxx',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'فون نمبر ضروری ہے';
                          }
                          if (v.trim().length < 10) {
                            return 'درست فون نمبر درج کریں';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _address,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'پتہ *',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'پتہ ضروری ہے'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'پاس ورڈ *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'پاس ورڈ ضروری ہے';
                          }
                          if (v.trim().length < 4) {
                            return 'کم از کم 4 حروف';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirm,
                        obscureText: _obscure,
                        decoration: const InputDecoration(
                          labelText: 'پاس ورڈ دوبارہ *',
                          prefixIcon: Icon(Icons.lock_person_outlined),
                        ),
                        validator: (v) {
                          if (v != _password.text) {
                            return 'پاس ورڈ مماثل نہیں';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (_loading || !_canRegister) ? null : _register,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor:
                      _canRegister ? AppColors.teal : AppColors.muted,
                ),
                child: Text(
                  _loading
                      ? 'رجسٹر ہو رہا ہے...'
                      : (_canRegister
                          ? 'اکاؤنٹ رجسٹر کریں'
                          : 'پہلے نام، فون اور پتہ بھریں'),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              if (!widget.isFirstLaunch) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('پہلے سے اکاؤنٹ ہے؟ لاگ اِن'),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                Ur.appName,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
