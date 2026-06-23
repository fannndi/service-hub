import 'package:intl/intl.dart';

final _currency =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final _date = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

String money(num value) => _currency.format(value);
String dateText(DateTime value) =>
    value.millisecondsSinceEpoch == 0 ? '-' : _date.format(value);
