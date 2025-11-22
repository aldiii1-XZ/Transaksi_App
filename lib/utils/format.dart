import 'package:intl/intl.dart';

String formatRupiah(dynamic value) {
  if (value == null) return '0';
  try {
    final s = value.toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (s.isEmpty) return '0';
    final n = int.parse(s);
    return NumberFormat('#,###', 'id_ID').format(n).replaceAll(',', '.');
  } catch (e) {
    return value.toString();
  }
}
