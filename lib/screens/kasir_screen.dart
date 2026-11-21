import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key});

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  final _searchCtrl = TextEditingController();
  List<Product> _produk = [];
  final List<CartItem> _keranjang = [];
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
        _keranjang.add(CartItem(product: p));
      }
    });
  }

  void _ubahJumlah(CartItem item, double delta) {
    setState(() {
      item.jumlah += delta;
      if (item.jumlah <= 0) _keranjang.remove(item);
    });
  }

  double get _total => _keranjang.fold(0, (sum, c) => sum + c.subtotal);
  int get _totalItem => _keranjang.fold(0, (sum, c) => sum + c.jumlah.toInt());

  void _bukaKeranjang() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LembarKeranjang(
        keranjang: _keranjang,
        onUbahJumlah: _ubahJumlah,
        onSelesai: () async {
          await _muatProduk();
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _muatProduk(_searchCtrl.text),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => _muatProduk(v),
              decoration: InputDecoration(
                hintText: 'Cari nama barang...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          _muatProduk();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _produk.isEmpty
                    ? Center(child: Text('Barang tidak ditemukan', style: Theme.of(context).textTheme.bodyMedium))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.92,
                        ),
                        itemCount: _produk.length,
                        itemBuilder: (context, i) {
                          final p = _produk[i];
                          final diKeranjang = _keranjang.where((c) => c.product.id == p.id).firstOrNull;
                          return _KartuProdukKasir(
                            produk: p,
                            jumlahDiKeranjang: diKeranjang?.jumlah.toInt() ?? 0,
                            onTap: p.stok > 0 ? () => _tambahKeKeranjang(p) : null,
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
              backgroundColor: AppColors.primary,
              icon: Badge(
                label: Text('$_totalItem'),
                child: const Icon(Icons.shopping_cart_rounded),
              ),
              label: Text(formatRupiah(_total)),
            ),
    );
  }
}

class _KartuProdukKasir extends StatelessWidget {
  final Product produk;
  final int jumlahDiKeranjang;
  final VoidCallback? onTap;

  const _KartuProdukKasir({required this.produk, required this.jumlahDiKeranjang, this.onTap});

  @override
  Widget build(BuildContext context) {
    final habis = produk.stok <= 0;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: habis ? Colors.grey.shade200 : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.inventory_2_rounded, color: habis ? Colors.grey : AppColors.primary, size: 28),
              ),
              const Spacer(),
              Text(
                produk.namaBarang,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(formatRupiah(produk.hargaJual),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
              if (habis)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Stok habis', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                )
              else if (jumlahDiKeranjang > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                    child: Text('$jumlahDiKeranjang di keranjang',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LembarKeranjang extends StatefulWidget {
  final List<CartItem> keranjang;
  final void Function(CartItem, double) onUbahJumlah;
  final VoidCallback onSelesai;

  const _LembarKeranjang({required this.keranjang, required this.onUbahJumlah, required this.onSelesai});

  @override
  State<_LembarKeranjang> createState() => _LembarKeranjangState();
}

class _LembarKeranjangState extends State<_LembarKeranjang> {
  String _metodeBayar = 'tunai';
  final _uangDiterimaCtrl = TextEditingController();
  bool _memproses = false;

  double get _total => widget.keranjang.fold(0, (sum, c) => sum + c.subtotal);

  Future<void> _bayar() async {
    setState(() => _memproses = true);
    try {
      final uangDiterima = double.tryParse(_uangDiterimaCtrl.text.replaceAll('.', ''));
      final items = widget.keranjang
          .map((c) => {
                'product_id': c.product.id,
                'nama': c.product.namaBarang,
                'harga_satuan': c.product.hargaJual,
                'jumlah': c.jumlah,
                'subtotal': c.subtotal,
              })
          .toList();

      final invoice = await SupabaseService.instance.simpanTransaksiPenjualan(
        items: items,
        total: _total,
        metodeBayar: _metodeBayar,
        uangDiterima: uangDiterima,
        kembalian: uangDiterima != null ? uangDiterima - _total : null,
      );

      widget.keranjang.clear();
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSelesai();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaksi $invoice berhasil disimpan'), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan transaksi: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _memproses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(height: 4, width: 48, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Keranjang Belanja', style: Theme.of(context).textTheme.titleLarge),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.keranjang.length,
                  itemBuilder: (context, i) {
                    final item = widget.keranjang[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.namaBarang, style: Theme.of(context).textTheme.titleMedium),
                                Text(formatRupiah(item.product.hargaJual), style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          _StepperJumlah(
                            jumlah: item.jumlah,
                            onKurang: () => setState(() => widget.onUbahJumlah(item, -1)),
                            onTambah: () => setState(() => widget.onUbahJumlah(item, 1)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: Theme.of(context).textTheme.titleLarge),
                        Text(formatRupiah(_total),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'tunai', label: Text('Tunai'), icon: Icon(Icons.payments_outlined)),
                        ButtonSegment(value: 'qris', label: Text('QRIS'), icon: Icon(Icons.qr_code_rounded)),
                        ButtonSegment(value: 'kasbon', label: Text('Kasbon'), icon: Icon(Icons.book_outlined)),
                      ],
                      selected: {_metodeBayar},
                      onSelectionChanged: (s) => setState(() => _metodeBayar = s.first),
                    ),
                    if (_metodeBayar == 'tunai') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _uangDiterimaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Uang diterima (opsional)', prefixText: 'Rp '),
                      ),
                    ],
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: widget.keranjang.isEmpty || _memproses ? null : _bayar,
                      child: _memproses
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Selesaikan Transaksi'),
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

class _StepperJumlah extends StatelessWidget {
  final double jumlah;
  final VoidCallback onTambah;
  final VoidCallback onKurang;

  const _StepperJumlah({required this.jumlah, required this.onTambah, required this.onKurang});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.remove_rounded), onPressed: onKurang, visualDensity: VisualDensity.compact),
          SizedBox(width: 28, child: Text('${jumlah.toInt()}', textAlign: TextAlign.center)),
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: onTambah, visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
