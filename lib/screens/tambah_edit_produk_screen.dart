import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

/// Satu layar dipakai untuk dua keperluan: tambah barang baru (produk == null)
/// dan edit barang yang sudah ada (produk != null). Ini menyederhanakan alur
/// dan memastikan tampilan form konsisten.
class TambahEditProdukScreen extends StatefulWidget {
  final Product? produk;
  const TambahEditProdukScreen({super.key, this.produk});

  @override
  State<TambahEditProdukScreen> createState() => _TambahEditProdukScreenState();
}

class _TambahEditProdukScreenState extends State<TambahEditProdukScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _satuanCtrl;
  late final TextEditingController _modalCtrl;
  late final TextEditingController _jualCtrl;
  late final TextEditingController _packCtrl;
  late final TextEditingController _stokCtrl;
  late final TextEditingController _stokMinCtrl;
  bool _menyimpan = false;

  bool get _modeEdit => widget.produk != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produk;
    _namaCtrl = TextEditingController(text: p?.namaBarang ?? '');
    _satuanCtrl = TextEditingController(text: p?.satuan ?? 'pcs');
    _modalCtrl = TextEditingController(text: p != null ? p.hargaModal.toStringAsFixed(0) : '');
    _jualCtrl = TextEditingController(text: p != null ? p.hargaJual.toStringAsFixed(0) : '');
    _packCtrl = TextEditingController(text: p?.hargaPack != null ? p!.hargaPack!.toStringAsFixed(0) : '');
    _stokCtrl = TextEditingController(text: p != null ? p.stok.toStringAsFixed(0) : '0');
    _stokMinCtrl = TextEditingController(text: p != null ? p.stokMinimum.toStringAsFixed(0) : '5');
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);
    try {
      final data = {
        'nama_barang': _namaCtrl.text.trim(),
        'satuan': _satuanCtrl.text.trim().isEmpty ? 'pcs' : _satuanCtrl.text.trim(),
        'harga_modal': double.tryParse(_modalCtrl.text) ?? 0,
        'harga_jual': double.tryParse(_jualCtrl.text) ?? 0,
        'harga_pack': _packCtrl.text.trim().isEmpty ? null : double.tryParse(_packCtrl.text),
        'stok': double.tryParse(_stokCtrl.text) ?? 0,
        'stok_minimum': double.tryParse(_stokMinCtrl.text) ?? 5,
      };

      if (_modeEdit) {
        await SupabaseService.instance.updateProduk(widget.produk!.id, data);
      } else {
        await SupabaseService.instance.tambahProduk(Product(
          id: '',
          namaBarang: data['nama_barang'] as String,
          satuan: data['satuan'] as String,
          hargaModal: data['harga_modal'] as double,
          hargaJual: data['harga_jual'] as double,
          hargaPack: data['harga_pack'] as double?,
          stok: data['stok'] as double,
          stokMinimum: data['stok_minimum'] as double,
        ));
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  Future<void> _hapus() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus barang?'),
        content: Text('"${widget.produk!.namaBarang}" akan disembunyikan dari daftar barang. Riwayat transaksi lama tetap aman.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (konfirmasi == true) {
      await SupabaseService.instance.nonaktifkanProduk(widget.produk!.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_modeEdit ? 'Edit Barang' : 'Tambah Barang'),
        actions: [
          if (_modeEdit)
            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger), onPressed: _hapus),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _namaCtrl,
              decoration: const InputDecoration(labelText: 'Nama Barang *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _satuanCtrl,
              decoration: const InputDecoration(labelText: 'Satuan (pcs, kg, liter, renteng, dus...)'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _modalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga Modal', prefixText: 'Rp '),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _jualCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga Jual *', prefixText: 'Rp '),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _packCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga Jual per Pack/Dus (opsional)', prefixText: 'Rp '),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stokCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stok Saat Ini'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stokMinCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Batas Stok Menipis'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _menyimpan ? null : _simpan,
              child: _menyimpan
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(_modeEdit ? 'Simpan Perubahan' : 'Tambah Barang'),
            ),
          ],
        ),
      ),
    );
  }
}
