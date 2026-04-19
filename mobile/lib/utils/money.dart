import 'package:intl/intl.dart';

String formatCents(int cents, [String currency = 'USD']) {
  final fmt = NumberFormat.currency(name: currency, symbol: _symbolFor(currency));
  return fmt.format(cents / 100);
}

String _symbolFor(String currency) {
  switch (currency.toUpperCase()) {
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    case 'JPY':
      return '¥';
    case 'INR':
      return '₹';
    default:
      return '$currency ';
  }
}

/// Parse a free-form currency string (e.g. "12.34", "$12.34") into cents.
/// Returns `null` if the value cannot be parsed.
int? parseCents(String input) {
  final trimmed = input.trim().replaceAll(RegExp(r'[^0-9\.\-]'), '');
  if (trimmed.isEmpty) return null;
  final v = double.tryParse(trimmed);
  if (v == null) return null;
  return (v * 100).round();
}
