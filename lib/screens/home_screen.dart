import 'package:flutter/material.dart';
import 'kasir_screen.dart';
import 'produk_screen.dart';
import 'pembelian_screen.dart';
import 'laporan_screen.dart';
import 'beranda_screen.dart';

/// Shell utama aplikasi: bottom navigation besar & jelas
/// agar mudah dipakai meski oleh pengguna yang tidak terbiasa HP.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _pages = const [
    BerandaScreen(),
    KasirScreen(),
    ProdukScreen(),
    PembelianScreen(),
    LaporanScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 26,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale_rounded), label: 'Kasir'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Stok'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping_rounded), label: 'Belanja'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Laporan'),
        ],
      ),
    );
  }
}
