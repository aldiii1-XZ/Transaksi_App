import 'package:intl/intl.dart';

/// Format angka menjadi Rupiah dengan titik
/// Contoh: 10000 → 10.000
String formatRupiah(String raw) {
  if (raw.isEmpty) return "";

  // Hapus titik lama
  raw = raw.replaceAll('.', '');

  // Jika bukan angka → langsung kembalikan raw
  final number = int.tryParse(raw);
  if (number == null) return raw;

  return NumberFormat.decimalPattern('id').format(number);
}

/// Convert angka mentah ke tampilan Rupiah
String formatRupiahInt(int value) {
  return NumberFormat.decimalPattern('id').format(value);
}
