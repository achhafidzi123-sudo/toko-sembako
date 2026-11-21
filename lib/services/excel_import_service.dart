import 'dart:io';
import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Kolom wajib pada template Excel import barang.
/// Urutan ini HARUS sama dengan yang dibuat di [buatFileTemplate].
const List<String> kolomTemplateBarang = [
  'nama_barang',
  'satuan',
  'harga_modal',
  'harga_jual',
  'harga_pack',
  'stok',
];

class ExcelImportService {
  /// Membuat file template Excel kosong (hanya header + 1 baris contoh)
  /// lalu mengembalikan path file-nya agar bisa dibagikan/dibuka user.
  static Future<File> buatFileTemplate() async {
    final workbook = xls.Excel.createExcel();
    final sheetName = workbook.getDefaultSheet()!;
    final sheet = workbook[sheetName];

    sheet.appendRow(kolomTemplateBarang.map((e) => xls.TextCellValue(e)).toList());
    sheet.appendRow([
      xls.TextCellValue('Contoh: Beras 5kg'),
      xls.TextCellValue('pcs'),
      xls.IntCellValue(70000),
      xls.IntCellValue(75000),
      xls.IntCellValue(0),
      xls.IntCellValue(10),
    ]);

    for (var i = 0; i < kolomTemplateBarang.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/template_import_barang.xlsx');
    final bytes = workbook.save();
    await file.writeAsBytes(bytes!);
    return file;
  }

  /// Membagikan file template (buka menu share bawaan HP: WhatsApp, simpan ke Drive, dll)
  static Future<void> bagikanTemplate() async {
    final file = await buatFileTemplate();
    await Share.shareXFiles([XFile(file.path)], text: 'Template import barang - Toko Sembako');
  }

  /// Membuka file picker agar user memilih file .xlsx dari HP-nya,
  /// lalu mem-parsing isinya menjadi list of map siap dipakai SupabaseService.importProdukMassal.
  static Future<List<Map<String, dynamic>>?> pilihDanBacaFileExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null || result.files.single.path == null) return null;

    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();
    final workbook = xls.Excel.decodeBytes(bytes);
    final sheet = workbook.tables[workbook.tables.keys.first]!;

    if (sheet.maxRows < 2) return [];

    final headerRow = sheet.rows.first
        .map((c) => (c?.value?.toString() ?? '').trim().toLowerCase())
        .toList();

    final rows = <Map<String, dynamic>>[];
    for (var r = 1; r < sheet.maxRows; r++) {
      final row = sheet.rows[r];
      if (row.every((c) => c?.value == null)) continue; // lewati baris kosong

      final map = <String, dynamic>{};
      for (var c = 0; c < headerRow.length && c < row.length; c++) {
        final key = headerRow[c];
        if (key.isEmpty) continue;
        final cell = row[c]?.value;
        map[key] = _parseCellValue(key, cell);
      }
      rows.add(map);
    }
    return rows;
  }

  static dynamic _parseCellValue(String kolom, dynamic cell) {
    if (cell == null) return null;
    if (kolom == 'nama_barang' || kolom == 'satuan') {
      return cell.toString().trim();
    }
    // Kolom angka: harga_modal, harga_jual, harga_pack, stok
    if (cell is xls.IntCellValue) return cell.value.toDouble();
    if (cell is xls.DoubleCellValue) return cell.value;
    final parsed = double.tryParse(cell.toString().replaceAll(RegExp(r'[^0-9.]'), ''));
    return parsed;
  }
}
