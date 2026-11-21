import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';
import '../services/excel_import_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'tambah_edit_produk_screen.dart';

class ProdukScreen extends StatefulWidget {
  const ProdukScreen({super.key});

  @override
  State<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends State<ProdukScreen> {
  final _searchCtrl = TextEditingController();
  List<Product> _produk = [];
  bool _loading = true;
  bool _mengimpor = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat([String? search]) async {
    setState(() => _loading = true);
    final data = await SupabaseService.instance.getProducts(search: search);
    if (!mounted) return;
    setState(() {
      _produk = data;
      _loading = false;
    });
  }

  Future<void> _bukaFormTambah() async {
    final hasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TambahEditProdukScreen()),
    );
    if (hasil == true) _muat(_searchCtrl.text);
  }

  Future<void> _bukaFormEdit(Product p) async {
    final hasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TambahEditProdukScreen(produk: p)),
    );
    if (hasil == true) _muat(_searchCtrl.text);
  }

  Future<void> _unduhTemplate() async {
    try {
      await ExcelImportService.bagikanTemplate();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat template: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _importExcel() async {
    try {
      final baris = await ExcelImportService.pilihDanBacaFileExcel();
      if (baris == null) return; // user batal pilih file
      if (baris.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File kosong atau tidak ada data barang')),
          );
        }
        return;
      }

      final konfirmasi = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Import Barang'),
          content: Text(
            'Ditemukan ${baris.length} baris barang di file ini.\n\n'
            'Barang dengan nama yang SAMA dengan yang sudah ada akan di-update harganya. '
            'Barang baru akan ditambahkan ke daftar.\n\nLanjutkan?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Import')),
          ],
        ),
      );
      if (konfirmasi != true) return;

      setState(() => _mengimpor = true);
      final hasil = await SupabaseService.instance.importProdukMassal(baris);
      setState(() => _mengimpor = false);

      await _muat();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import selesai: ${hasil.ditambah} barang baru, ${hasil.diupdate} diperbarui'
              '${hasil.gagal > 0 ? ', ${hasil.gagal} gagal' : ''}',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      setState(() => _mengimpor = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal import: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _bukaMenuTambah() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(height: 4, width: 48, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(Icons.add_rounded, color: AppColors.primary)),
              title: const Text('Tambah Barang Manual'),
              subtitle: const Text('Isi form satu per satu'),
              onTap: () {
                Navigator.pop(context);
                _bukaFormTambah();
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(Icons.upload_file_rounded, color: AppColors.primary)),
              title: const Text('Import dari Excel'),
              subtitle: const Text('Tambah banyak barang sekaligus dari file'),
              onTap: () {
                Navigator.pop(context);
                _importExcel();
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(Icons.description_rounded, color: AppColors.primary)),
              title: const Text('Download Template Excel'),
              subtitle: const Text('Dapatkan format file untuk import'),
              onTap: () {
                Navigator.pop(context);
                _unduhTemplate();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stok & Barang')),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => _muat(v),
                  decoration: InputDecoration(
                    hintText: 'Cari barang...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { _searchCtrl.clear(); _muat(); })
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _produk.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text('Belum ada barang', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text('Tekan tombol + untuk menambah barang', style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                            itemCount: _produk.length,
                            itemBuilder: (context, i) {
                              final p = _produk[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  onTap: () => _bukaFormEdit(p),
                                  leading: CircleAvatar(
                                    backgroundColor: p.stokMenipis ? const Color(0xFFFFEBEE) : AppColors.primaryLight,
                                    child: Icon(Icons.inventory_2_rounded, color: p.stokMenipis ? AppColors.danger : AppColors.primary),
                                  ),
                                  title: Text(p.namaBarang, style: Theme.of(context).textTheme.titleMedium),
                                  subtitle: Text(
                                    '${formatRupiah(p.hargaJual)} • Stok: ${formatAngka(p.stok)} ${p.satuan}',
                                  ),
                                  trailing: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
          if (_mengimpor)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Mengimpor barang...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bukaMenuTambah,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Barang'),
      ),
    );
  }
}
