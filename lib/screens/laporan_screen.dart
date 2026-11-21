import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

enum _Periode { hari7, hari30, bulanIni }

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  _Periode _periode = _Periode.hari7;
  bool _loading = true;

  double _totalOmzet = 0;
  double _totalModal = 0;
  int _jumlahTransaksi = 0;
  Map<String, double> _omzetPerHari = {};

  @override
  void initState() {
    super.initState();
    _muat();
  }

  (DateTime, DateTime) _rentangWaktu() {
    final sekarang = DateTime.now();
    switch (_periode) {
      case _Periode.hari7:
        return (sekarang.subtract(const Duration(days: 6)), sekarang);
      case _Periode.hari30:
        return (sekarang.subtract(const Duration(days: 29)), sekarang);
      case _Periode.bulanIni:
        return (DateTime(sekarang.year, sekarang.month, 1), sekarang);
    }
  }

  Future<void> _muat() async {
    setState(() => _loading = true);
    final (dari, sampai) = _rentangWaktu();
    final penjualan = await SupabaseService.instance.getPenjualanRange(dari, sampai);

    double omzet = 0;
    final Map<String, double> perHari = {};

    for (final s in penjualan) {
      final total = (s['total'] as num?)?.toDouble() ?? 0;
      omzet += total;

      final tgl = DateTime.parse(s['created_at'] as String);
      final key = formatTanggalSingkat(tgl);
      perHari[key] = (perHari[key] ?? 0) + total;
    }

    if (!mounted) return;
    setState(() {
      _totalOmzet = omzet;
      _jumlahTransaksi = penjualan.length;
      _omzetPerHari = perHari;
      _totalModal = 0; // Estimasi laba memerlukan data harga modal per item; disederhanakan di versi awal
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = _omzetPerHari.entries.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _muat,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SegmentedButton<_Periode>(
                    segments: const [
                      ButtonSegment(value: _Periode.hari7, label: Text('7 Hari')),
                      ButtonSegment(value: _Periode.hari30, label: Text('30 Hari')),
                      ButtonSegment(value: _Periode.bulanIni, label: Text('Bulan Ini')),
                    ],
                    selected: {_periode},
                    onSelectionChanged: (s) {
                      setState(() => _periode = s.first);
                      _muat();
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _KartuStat(
                          label: 'Total Penjualan',
                          nilai: formatRupiah(_totalOmzet),
                          ikon: Icons.trending_up_rounded,
                          warna: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KartuStat(
                          label: 'Jumlah Transaksi',
                          nilai: '$_jumlahTransaksi',
                          ikon: Icons.receipt_long_rounded,
                          warna: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Grafik Penjualan', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
                      child: SizedBox(
                        height: 220,
                        child: entries.isEmpty
                            ? Center(child: Text('Belum ada transaksi di periode ini', style: Theme.of(context).textTheme.bodyMedium))
                            : BarChart(
                                BarChartData(
                                  borderData: FlBorderData(show: false),
                                  gridData: const FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final i = value.toInt();
                                          if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                                          final label = entries[i].key.split(' ').take(2).join(' ');
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(label, style: const TextStyle(fontSize: 10)),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  barGroups: [
                                    for (var i = 0; i < entries.length; i++)
                                      BarChartGroupData(x: i, barRods: [
                                        BarChartRodData(
                                          toY: entries[i].value,
                                          color: AppColors.primary,
                                          width: 16,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ]),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Rincian Harian', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ...entries.reversed.map(
                    (e) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                        title: Text(e.key),
                        trailing: Text(formatRupiah(e.value), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _KartuStat extends StatelessWidget {
  final String label;
  final String nilai;
  final IconData ikon;
  final Color warna;

  const _KartuStat({required this.label, required this.nilai, required this.ikon, required this.warna});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ikon, color: warna, size: 22),
            const SizedBox(height: 10),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 2),
            Text(nilai, style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
