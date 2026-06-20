import 'package:intl/intl.dart';

class NumberFormatter {
  static String formatRupiah(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
  
  static String formatRupiahWithDecimal(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
  
  static String formatNumber(double number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }
  
  static double parseRupiah(String formatted) {
    return double.parse(formatted.replaceAll(RegExp(r'[^0-9]'), ''));
  }
  
  static String formatPersen(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
}