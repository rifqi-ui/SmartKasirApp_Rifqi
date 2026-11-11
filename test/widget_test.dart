import 'package:flutter_test/flutter_test.dart';
import 'package:smartkasir_app/models/produk.dart';

void main() {
  test('Produk toMap dan fromMap konsisten', () {
    const p = Produk(
      kodeProduk: 'T-1',
      nama: 'Tes',
      kategori: 'Snack',
      hargaBeli: 1000,
      hargaJual: 2000,
      stok: 3,
      gambarUrl: '',
    );
    final q = Produk.fromMap(p.toMap());
    expect(q.nama, 'Tes');
    expect(q.hargaJual, 2000);
  });
}
