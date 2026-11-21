class Product {
  final String id;
  final String namaBarang;
  final String? categoryId;
  final String? categoryNama;
  final String satuan;
  final double hargaModal;
  final double hargaJual;
  final double? hargaPack;
  final double stok;
  final double stokMinimum;
  final String? barcode;
  final bool aktif;

  Product({
    required this.id,
    required this.namaBarang,
    this.categoryId,
    this.categoryNama,
    required this.satuan,
    required this.hargaModal,
    required this.hargaJual,
    this.hargaPack,
    required this.stok,
    required this.stokMinimum,
    this.barcode,
    this.aktif = true,
  });

  bool get stokMenipis => stok <= stokMinimum;

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      namaBarang: map['nama_barang'] as String,
      categoryId: map['category_id'] as String?,
      categoryNama: map['categories'] != null ? map['categories']['nama'] as String? : null,
      satuan: map['satuan'] as String? ?? 'pcs',
      hargaModal: (map['harga_modal'] as num?)?.toDouble() ?? 0,
      hargaJual: (map['harga_jual'] as num?)?.toDouble() ?? 0,
      hargaPack: (map['harga_pack'] as num?)?.toDouble(),
      stok: (map['stok'] as num?)?.toDouble() ?? 0,
      stokMinimum: (map['stok_minimum'] as num?)?.toDouble() ?? 5,
      barcode: map['barcode'] as String?,
      aktif: map['aktif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'nama_barang': namaBarang,
      'category_id': categoryId,
      'satuan': satuan,
      'harga_modal': hargaModal,
      'harga_jual': hargaJual,
      'harga_pack': hargaPack,
      'stok': stok,
      'stok_minimum': stokMinimum,
      'barcode': barcode,
      'aktif': aktif,
    };
  }
}

class ProductCategory {
  final String id;
  final String nama;

  ProductCategory({required this.id, required this.nama});

  factory ProductCategory.fromMap(Map<String, dynamic> map) {
    return ProductCategory(id: map['id'] as String, nama: map['nama'] as String);
  }
}
