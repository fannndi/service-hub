import 'package:intl/intl.dart';

import '../core/l10n/app_localizations.dart';

String formatRupiah(num amount) {
  final f = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
  return f.format(amount);
}

String formatShortDate(DateTime? dt, {AppLocalizations? l10n}) {
  if (dt == null) return '-';
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return l10n?.justNow ?? 'Baru saja';
  if (diff.inHours < 1) return '${diff.inMinutes}m ${l10n?.ago ?? 'lalu'}';
  if (diff.inDays < 1) return '${diff.inHours}h ${l10n?.ago ?? 'lalu'}';
  if (diff.inDays < 7) return '${diff.inDays}d ${l10n?.ago ?? 'lalu'}';
  return DateFormat('dd/MM/yyyy').format(dt);
}
