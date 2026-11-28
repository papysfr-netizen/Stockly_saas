import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

final _dateFmt = DateFormat('dd/MM/yyyy', 'fr_FR');
final _isoDay = DateFormat('yyyy-MM-dd');

String formatDate(DateTime? d) => d == null ? '-' : _dateFmt.format(d);
String isoDay(DateTime d) => _isoDay.format(d);

String formatMontant(num montant, {String devise = 'USD'}) {
  final f = NumberFormat('#,##0.##', 'fr_FR');
  return '${f.format(montant)} $devise';
}

String formatNote(double? n) => n == null ? '-' : n.toStringAsFixed(2);

DateTime? readDate(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v);
  if (v is DateTime) return v;
  return null;
}

double readDouble(dynamic v, [double fallback = 0]) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? fallback;
