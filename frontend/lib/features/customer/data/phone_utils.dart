String normalizePhone(String phone) {
  final d = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.startsWith('62')) return '08${d.substring(2)}';
  if (d.startsWith('8')) return '08${d.substring(1)}';
  if (d.startsWith('0')) return d;
  return '08$d';
}
