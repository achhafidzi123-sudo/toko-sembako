import 'product.dart';

/// Item di keranjang kasir (sementara, belum tersimpan ke database)
class CartItem {
  final Product product;
  double jumlah;

  CartItem({required this.product, this.jumlah = 1});

  double get subtotal => product.hargaJual * jumlah;
}

/// Item di keranjang belanja/pembelian ke supplier
class PurchaseCartItem {
  final Product product;
  double jumlah;
  double hargaBeli;

  PurchaseCartItem({
    required this.product,
    this.jumlah = 1,
    required this.hargaBeli,
  });

  double get subtotal => hargaBeli * jumlah;
}
