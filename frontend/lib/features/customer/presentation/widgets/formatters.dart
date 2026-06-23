import 'package:intl/intl.dart';

final rupiahFormatter =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final shortDateFormatter = DateFormat('dd MMM yyyy', 'id_ID');
String rupiah(num value) => rupiahFormatter.format(value);
String shortDate(DateTime? value) =>
    value == null ? '-' : shortDateFormatter.format(value);
