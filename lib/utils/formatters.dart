import 'package:intl/intl.dart';

final _rupiahFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final _angkaFormat = NumberFormat.decimalPattern('id_ID');

String formatRupiah(num value) => _rupiahFormat.format(value);

String formatAngka(num value) => _angkaFormat.format(value);

String formatTanggal(DateTime date) => DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(date);

String formatTanggalSingkat(DateTime date) => DateFormat('d MMM yyyy', 'id_ID').format(date);
