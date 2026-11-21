import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/supplier.dart';

/// Lapisan tunggal untuk semua akses ke Supabase.
/// Semua layar memanggil method di sini, bukan langsung ke SupabaseClient,
/// supaya query mudah diubah/ditest di satu tempat.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _db => Supabase.instance.client;

  // ---------------- AUTH ----------------
  // Pengguna cukup memakai "username" biasa (bukan email Gmail dkk).
  // Di balik layar, Supabase Auth tetap butuh format email, jadi username
  // diubah otomatis jadi "username@tokosembako.com" -- pengguna tidak perlu tahu ini.
  String _emailDariUsername(String username) {
    final bersih = username.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_.]'), '');
    return '$bersih@tokosembako.com';
  }

  Future<AuthResponse> login(String username, String password) {
    return _db.auth.signInWithPassword(
      email: _emailDariUsername(username),
      password: password,
    );
  }

  Future<AuthResponse> daftar({
    required String username,
    required String password,
    required String nama,
    required String namaToko,
  }) {
    return _db.auth.signUp(
      email: _emailDariUsername(username),
      password: password,
      data: {
        'nama': nama,
        'username': username.trim().toLowerCase(),
        'nama_toko': namaToko,
      },
    );
  }

  Future<void> logout() => _db.auth.signOut();

  User? get currentUser => _db.auth.currentUser;

  /// Ambil data profil (nama, username, nama toko) milik user yang sedang login.
  Future<Map<String, dynamic>?> getProfilSaya() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final res = await _db.from('profiles').select().eq('id', uid).maybeSingle();
    return res as Map<String, dynamic>?;
  }

  /// Ubah nama toko yang tampil di Beranda.
  Future<void> updateNamaToko(String namaToko) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await _db.from('profiles').update({'nama_toko': namaToko}).eq('id', uid);
  }

  // ---------------- KATEGORI ----------------
  Future<List<ProductCategory>> getCategories() async {
    final res = await _db.from('categories').select().order('nama');
    return (res as List).map((e) => ProductCategory.fromMap(e)).toList();
  }

  // ---------------- PRODUK ----------------
  Future<List<Product>> getProducts({String? search, String? categoryId}) async {
    var query = _db.from('products').select('*, categories(nama)').eq('aktif', true);
    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('nama_barang', '%${search.trim()}%');
    }
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    final res = await query.order('nama_barang');
    return (res as List).map((e) => Product.fromMap(e)).toList();
  }

  Future<List<Product>> getProdukStokMenipis() async {
    final res = await _db
        .from('products')
        .select('*, categories(nama)')
        .eq('aktif', true)
        .order('stok');
    return (res as List)
        .map((e) => Product.fromMap(e))
        .where((p) => p.stokMenipis)
        .toList();
  }

  Future<void> tambahProduk(Product produk) async {
    await _db.from('products').insert(produk.toInsertMap());
  }

  Future<void> updateProduk(String id, Map<String, dynamic> perubahan) async {
    await _db.from('products').update(perubahan).eq('id', id);
  }

  Future<void> nonaktifkanProduk(String id) async {
    await _db.from('products').update({'aktif': false}).eq('id', id);
  }

  /// Import massal dari file Excel. Baris yang nama_barang-nya sama (case-insensitive)
  /// dengan produk yang sudah ada akan di-update, sisanya ditambahkan sebagai baru.
  Future<ImportResult> importProdukMassal(List<Map<String, dynamic>> baris) async {
    final existing = await _db.from('products').select('id, nama_barang');
    final mapExisting = <String, String>{
      for (final p in (existing as List)) (p['nama_barang'] as String).toLowerCase(): p['id'] as String,
    };

    int ditambah = 0;
    int diupdate = 0;
    int gagal = 0;

    for (final row in baris) {
      try {
        final nama = (row['nama_barang'] as String?)?.trim();
        if (nama == null || nama.isEmpty) continue;

        final data = {
          'nama_barang': nama,
          'satuan': (row['satuan'] as String?)?.trim().isNotEmpty == true ? row['satuan'] : 'pcs',
          'harga_modal': row['harga_modal'] ?? 0,
          'harga_jual': row['harga_jual'] ?? 0,
          'harga_pack': row['harga_pack'],
          'stok': row['stok'] ?? 0,
        };

        final existingId = mapExisting[nama.toLowerCase()];
        if (existingId != null) {
          await _db.from('products').update(data).eq('id', existingId);
          diupdate++;
        } else {
          await _db.from('products').insert(data);
          ditambah++;
        }
      } catch (_) {
        gagal++;
      }
    }
    return ImportResult(ditambah: ditambah, diupdate: diupdate, gagal: gagal);
  }

  // ---------------- TRANSAKSI PENJUALAN (KASIR) ----------------
  Future<String> simpanTransaksiPenjualan({
    required List<Map<String, dynamic>> items, // product_id, nama, harga_satuan, jumlah, subtotal
    required double total,
    required String metodeBayar,
    double? uangDiterima,
    double? kembalian,
    String? namaPelanggan,
  }) async {
    final nomorInvoice = 'INV-${DateTime.now().millisecondsSinceEpoch}';
    final sale = await _db
        .from('sales')
        .insert({
          'nomor_invoice': nomorInvoice,
          'total': total,
          'metode_bayar': metodeBayar,
          'uang_diterima': uangDiterima,
          'kembalian': kembalian,
          'nama_pelanggan': namaPelanggan,
          'kasir_id': currentUser?.id,
        })
        .select()
        .single();

    final saleId = sale['id'] as String;

    final itemRows = items
        .map((it) => {
              'sale_id': saleId,
              'product_id': it['product_id'],
              'nama_barang_snapshot': it['nama'],
              'harga_satuan': it['harga_satuan'],
              'jumlah': it['jumlah'],
              'subtotal': it['subtotal'],
            })
        .toList();

    await _db.from('sale_items').insert(itemRows);
    return nomorInvoice;
  }

  // ---------------- SUPPLIER ----------------
  Future<List<Supplier>> getSuppliers() async {
    final res = await _db.from('suppliers').select().order('nama');
    return (res as List).map((e) => Supplier.fromMap(e)).toList();
  }

  Future<void> tambahSupplier(Supplier s) async {
    await _db.from('suppliers').insert(s.toInsertMap());
  }

  // ---------------- PEMBELIAN (BELANJA KE PABRIK/SUPPLIER) ----------------
  Future<void> simpanPembelian({
    String? supplierId,
    String? nomorNota,
    required List<Map<String, dynamic>> items, // product_id, nama, harga_beli_satuan, jumlah, subtotal
    required double total,
    String statusBayar = 'lunas',
    double jumlahDibayar = 0,
    String? catatan,
  }) async {
    final purchase = await _db
        .from('purchases')
        .insert({
          'nomor_nota': nomorNota,
          'supplier_id': supplierId,
          'total': total,
          'status_bayar': statusBayar,
          'jumlah_dibayar': jumlahDibayar,
          'catatan': catatan,
          'dibuat_oleh': currentUser?.id,
        })
        .select()
        .single();

    final purchaseId = purchase['id'] as String;

    final itemRows = items
        .map((it) => {
              'purchase_id': purchaseId,
              'product_id': it['product_id'],
              'nama_barang_snapshot': it['nama'],
              'harga_beli_satuan': it['harga_beli_satuan'],
              'jumlah': it['jumlah'],
              'subtotal': it['subtotal'],
            })
        .toList();

    await _db.from('purchase_items').insert(itemRows);
  }

  // ---------------- LAPORAN ----------------
  Future<List<Map<String, dynamic>>> getPenjualanRange(DateTime dari, DateTime sampai) async {
    final res = await _db
        .from('sales')
        .select('*, sale_items(*)')
        .gte('created_at', dari.toIso8601String())
        .lte('created_at', sampai.toIso8601String())
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }
}

class ImportResult {
  final int ditambah;
  final int diupdate;
  final int gagal;
  ImportResult({required this.ditambah, required this.diupdate, required this.gagal});
}
