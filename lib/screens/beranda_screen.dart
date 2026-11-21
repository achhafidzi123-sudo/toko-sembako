import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../models/product.dart';

/// Halaman Beranda: ringkasan singkat kondisi toko hari ini,
/// dirancang agar pemilik toko langsung paham situasi tanpa perlu menggali menu lain.
class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  bool _loading = true;
  double _totalHariIni = 0;
  int _jumlahTransaksi = 0;
  List<Product> _stokMenipis = [];

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() => _loading = true);
    final sekarang = DateTime.now();
    final awalHari = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final penjualan = await SupabaseService.instance.getPenjualanRange(awalHari, sekarang);
    final stokMenipis = await SupabaseService.instance.getProdukStokMenipis();

    double total = 0;
    for (final s in penjualan) {
      total += (s['total'] as num?)?.toDouble() ?? 0;
    }

    if (!mounted) return;
    setState(() {
      _totalHariIni = total;
      _jumlahTransaksi = penjualan.length;
      _stokMenipis = stokMenipis;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final jamSapaan = DateTime.now().hour < 11
        ? 'Selamat pagi'
        : DateTime.now().hour < 15
            ? 'Selamat siang'
            : DateTime.now().hour < 18
                ? 'Selamat sore'
                : 'Selamat malam';

    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: RefreshIndicator(
        onRefresh: _muat,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(jamSapaan, style: Theme.of(context).textTheme.bodyMedium),
                  Text('Ini ringkasan toko kamu hari ini', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _KartuRingkasan(
                          label: 'Penjualan Hari Ini',
                          nilai: formatRupiah(_totalHariIni),
                          ikon: Icons.payments_rounded,
                          warna: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KartuRingkasan(
                          label: 'Transaksi',
                          nilai: '$_jumlahTransaksi',
                          ikon: Icons.receipt_long_rounded,
                          warna: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Stok Menipis', style: Theme.of(context).textTheme.titleLarge),
                      if (_stokMenipis.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${_stokMenipis.length} barang',
                              style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_stokMenipis.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(child: Text('Semua stok aman', style: Theme.of(context).textTheme.bodyLarge)),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._stokMenipis.take(6).map(
                          (p) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFFEBEE),
                                child: Icon(Icons.inventory_2_outlined, color: AppColors.danger),
                              ),
                              title: Text(p.namaBarang, style: Theme.of(context).textTheme.titleMedium),
                              subtitle: Text('Sisa stok: ${formatAngka(p.stok)} ${p.satuan}'),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          ),
                        ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'Created by Afi Hafidzi',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _KartuRingkasan extends StatelessWidget {
  final String label;
  final String nilai;
  final IconData ikon;
  final Color warna;

  const _KartuRingkasan({required this.label, required this.nilai, required this.ikon, required this.warna});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: warna.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(ikon, color: warna, size: 22),
            ),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 2),
            Text(nilai, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
