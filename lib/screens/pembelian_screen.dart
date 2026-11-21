import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Layar "Belanja" — mencatat pembelian barang dari supplier/pabrik.
/// Saat disimpan, stok barang otomatis bertambah dan harga modal ter-update
/// (lihat trigger database fn_tambah_stok_pembelian di schema.sql).
class PembelianScreen extends StatefulWidget {
  const PembelianScreen({super.key});

  @override
  State<PembelianScreen> createState() => _PembelianScreenState();
}

class _PembelianScreenState extends State<PembelianScreen> {
  final _searchCtrl = TextEditingController();
  List<Product> _produk = [];
  final List<PurchaseCartItem> _keranjang = [];
  Supplier? _supplierTerpilih;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muatProduk();
  }

  Future<void> _muatProduk([String? search]) async {
    setState(() => _loading = true);
    final data = await SupabaseService.instance.getProducts(search: search);
    if (!mounted) return;
    setState(() {
      _produk = data;
      _loading = false;
    });
  }

  void _tambahKeKeranjang(Product p) {
    setState(() {
      final idx = _keranjang.indexWhere((c) => c.product.id == p.id);
      if (idx >= 0) {
        _keranjang[idx].jumlah += 1;
      } else {
        _keranjang.add(PurchaseCartItem(product: p, hargaBeli: p.hargaModal));
      }
    });
  }

  double get _total => _keranjang.fold(0, (sum, c) => sum + c.subtotal);

  Future<void> _pilihSupplier() async {
    final suppliers = await SupabaseService.instance.getSuppliers();
    if (!mounted) return;
    final hasil = await showModalBottomSheet<Supplier>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _LembarPilihSupplier(suppliers: suppliers),
    );
    if (hasil != null) setState(() => _supplierTerpilih = hasil);
  }

  void _bukaKeranjang() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LembarKeranjangBelanja(
        keranjang: _keranjang,
        supplier: _supplierTerpilih,
        onUbah: () => setState(() {}),
        onSelesai: () async {
          _keranjang.clear();
          _supplierTerpilih = null;
          await _muatProduk();
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Belanja ke Pemasok')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                InkWell(
                  onTap: _pilihSupplier,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _supplierTerpilih?.nama ?? 'Pilih pemasok / pabrik (opsional)',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => _muatProduk(v),
                  decoration: const InputDecoration(hintText: 'Cari barang yang dibeli...', prefixIcon: Icon(Icons.search_rounded)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: _produk.length,
                    itemBuilder: (context, i) {
                      final p = _produk[i];
                      final diKeranjang = _keranjang.where((c) => c.product.id == p.id).toList();
                      final jumlah = diKeranjang.isNotEmpty ? diKeranjang.first.jumlah.toInt() : 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => _tambahKeKeranjang(p),
                          leading: const CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(Icons.inventory_2_rounded, color: AppColors.primary)),
                          title: Text(p.namaBarang, style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Text('Modal terakhir: ${formatRupiah(p.hargaModal)} • Stok: ${formatAngka(p.stok)} ${p.satuan}'),
                          trailing: jumlah > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                                  child: Text('$jumlah', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                )
                              : const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _keranjang.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _bukaKeranjang,
              backgroundColor: AppColors.accent,
              icon: const Icon(Icons.shopping_basket_rounded),
              label: Text('${_keranjang.length} barang • ${formatRupiah(_total)}'),
            ),
    );
  }
}

class _LembarPilihSupplier extends StatefulWidget {
  final List<Supplier> suppliers;
  const _LembarPilihSupplier({required this.suppliers});

  @override
  State<_LembarPilihSupplier> createState() => _LembarPilihSupplierState();
}

class _LembarPilihSupplierState extends State<_LembarPilihSupplier> {
  late List<Supplier> _list = widget.suppliers;
  final _namaCtrl = TextEditingController();
  final _kontakCtrl = TextEditingController();
  bool _tambahBaru = false;

  Future<void> _simpanSupplierBaru() async {
    if (_namaCtrl.text.trim().isEmpty) return;
    final s = Supplier(id: '', nama: _namaCtrl.text.trim(), kontak: _kontakCtrl.text.trim());
    await SupabaseService.instance.tambahSupplier(s);
    final updated = await SupabaseService.instance.getSuppliers();
    if (!mounted) return;
    setState(() {
      _list = updated;
      _tambahBaru = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Pilih Pemasok', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Flexible(
                child: _tambahBaru
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(controller: _namaCtrl, decoration: const InputDecoration(labelText: 'Nama pemasok/pabrik')),
                          const SizedBox(height: 10),
                          TextField(controller: _kontakCtrl, decoration: const InputDecoration(labelText: 'Kontak (opsional)')),
                          const SizedBox(height: 14),
                          ElevatedButton(onPressed: _simpanSupplierBaru, child: const Text('Simpan Pemasok')),
                        ],
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          ..._list.map(
                            (s) => ListTile(
                              leading: const CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(Icons.local_shipping_outlined, color: AppColors.primary)),
                              title: Text(s.nama),
                              subtitle: s.kontak != null && s.kontak!.isNotEmpty ? Text(s.kontak!) : null,
                              onTap: () => Navigator.pop(context, s),
                            ),
                          ),
                          ListTile(
                            leading: const CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(Icons.add_rounded, color: AppColors.primary)),
                            title: const Text('Tambah Pemasok Baru'),
                            onTap: () => setState(() => _tambahBaru = true),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LembarKeranjangBelanja extends StatefulWidget {
  final List<PurchaseCartItem> keranjang;
  final Supplier? supplier;
  final VoidCallback onUbah;
  final VoidCallback onSelesai;

  const _LembarKeranjangBelanja({required this.keranjang, required this.supplier, required this.onUbah, required this.onSelesai});

  @override
  State<_LembarKeranjangBelanja> createState() => _LembarKeranjangBelanjaState();
}

class _LembarKeranjangBelanjaState extends State<_LembarKeranjangBelanja> {
  final _nomorNotaCtrl = TextEditingController();
  bool _menyimpan = false;

  double get _total => widget.keranjang.fold(0, (sum, c) => sum + c.subtotal);

  Future<void> _simpan() async {
    setState(() => _menyimpan = true);
    try {
      final items = widget.keranjang
          .map((c) => {
                'product_id': c.product.id,
                'nama': c.product.namaBarang,
                'harga_beli_satuan': c.hargaBeli,
                'jumlah': c.jumlah,
                'subtotal': c.subtotal,
              })
          .toList();

      await SupabaseService.instance.simpanPembelian(
        supplierId: widget.supplier?.id,
        nomorNota: _nomorNotaCtrl.text.trim().isEmpty ? null : _nomorNotaCtrl.text.trim(),
        items: items,
        total: _total,
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSelesai();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembelian disimpan, stok barang diperbarui'), backgroundColor: AppColors.primary),
      );
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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(height: 4, width: 48, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Belanja dari ${widget.supplier?.nama ?? "pemasok"}', style: Theme.of(context).textTheme.titleLarge),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.keranjang.length,
                  itemBuilder: (context, i) {
                    final item = widget.keranjang[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(item.product.namaBarang, style: Theme.of(context).textTheme.titleMedium),
                          ),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: item.hargaBeli.toStringAsFixed(0),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Harga beli', isDense: true),
                              onChanged: (v) {
                                item.hargaBeli = double.tryParse(v) ?? item.hargaBeli;
                                widget.onUbah();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StepperJumlahBelanja(
                            jumlah: item.jumlah,
                            onKurang: () => setState(() {
                              item.jumlah -= 1;
                              if (item.jumlah <= 0) widget.keranjang.remove(item);
                            }),
                            onTambah: () => setState(() => item.jumlah += 1),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(controller: _nomorNotaCtrl, decoration: const InputDecoration(labelText: 'Nomor nota (opsional)')),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Belanja', style: Theme.of(context).textTheme.titleLarge),
                        Text(formatRupiah(_total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: widget.keranjang.isEmpty || _menyimpan ? null : _simpan,
                      child: _menyimpan
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Simpan Belanja Ini'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StepperJumlahBelanja extends StatelessWidget {
  final double jumlah;
  final VoidCallback onTambah;
  final VoidCallback onKurang;

  const _StepperJumlahBelanja({required this.jumlah, required this.onTambah, required this.onKurang});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.remove_rounded, size: 18), onPressed: onKurang, visualDensity: VisualDensity.compact),
          SizedBox(width: 22, child: Text('${jumlah.toInt()}', textAlign: TextAlign.center)),
          IconButton(icon: const Icon(Icons.add_rounded, size: 18), onPressed: onTambah, visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }
}
