import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _namaTokoCtrl = TextEditingController();
  bool _modeDaftar = false;
  bool _loading = false;
  bool _lihatPassword = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_modeDaftar) {
        await SupabaseService.instance.daftar(
          username: _usernameCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          nama: _namaCtrl.text.trim(),
          namaToko: _namaTokoCtrl.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Akun berhasil dibuat. Silakan login.')),
          );
          setState(() => _modeDaftar = false);
        }
      } else {
        await SupabaseService.instance.login(_usernameCtrl.text.trim(), _passCtrl.text.trim());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${e.toString()}'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.storefront_rounded, size: 46, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  Text('Toko Sembako', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                    _modeDaftar ? 'Buat akun baru untuk mulai' : 'Masuk untuk mulai berjualan',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (_modeDaftar) ...[
                    TextFormField(
                      controller: _namaCtrl,
                      decoration: const InputDecoration(labelText: 'Nama kamu', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _namaTokoCtrl,
                      decoration: const InputDecoration(labelText: 'Nama toko', prefixIcon: Icon(Icons.storefront_outlined)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama toko wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _usernameCtrl,
                    keyboardType: TextInputType.text,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_pin_outlined)),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Username wajib diisi';
                      if (v.trim().length < 4) return 'Minimal 4 karakter';
                      if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(v.trim())) {
                        return 'Hanya huruf, angka, titik, underscore';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: !_lihatPassword,
                    decoration: InputDecoration(
                      labelText: 'Kata sandi',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_lihatPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _lihatPassword = !_lihatPassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(_modeDaftar ? 'Daftar' : 'Masuk'),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => setState(() => _modeDaftar = !_modeDaftar),
                    child: Text(_modeDaftar ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Created by Afi Hafidzi',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
