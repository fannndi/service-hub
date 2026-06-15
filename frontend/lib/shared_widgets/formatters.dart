import 'package:intl/intl.dart';

String formatRupiah(num amount) {
  final f = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
  return f.format(amount);
}

String formatShortDate(DateTime? dt) {
  if (dt == null) return '-';
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inHours < 1) return '${diff.inMinutes}m lalu';
  if (diff.inDays < 1) return '${diff.inHours}h lalu';
  if (diff.inDays < 7) return '${diff.inDays}h lalu';
  return DateFormat('dd/MM/yyyy').format(dt);
}
