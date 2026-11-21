class Supplier {
  final String id;
  final String nama;
  final String? kontak;
  final String? alamat;
  final String? catatan;

  Supplier({required this.id, required this.nama, this.kontak, this.alamat, this.catatan});

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as String,
      nama: map['nama'] as String,
      kontak: map['kontak'] as String?,
      alamat: map['alamat'] as String?,
      catatan: map['catatan'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {'nama': nama, 'kontak': kontak, 'alamat': alamat, 'catatan': catatan};
  }
}
