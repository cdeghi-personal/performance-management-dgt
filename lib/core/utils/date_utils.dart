import 'package:intl/intl.dart';

final _dateFormatter = DateFormat('dd/MM/yyyy', 'pt_BR');
final _monthYearFormatter = DateFormat('MMMM yyyy', 'pt_BR');
final _shortMonthFormatter = DateFormat('MMM/yyyy', 'pt_BR');
final _isoFormatter = DateFormat('yyyy-MM-dd');

String formatDate(DateTime date) => _dateFormatter.format(date);

String formatMonthYear(DateTime date) {
  final s = _monthYearFormatter.format(date);
  return s[0].toUpperCase() + s.substring(1);
}

String formatShortMonth(DateTime date) => _shortMonthFormatter.format(date).toUpperCase();

String toIso(DateTime date) => _isoFormatter.format(date);

DateTime? parseIso(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  try {
    return DateTime.parse(iso);
  } catch (_) {
    return null;
  }
}

String formatDateOrEmpty(String? iso) {
  final d = parseIso(iso);
  return d != null ? formatDate(d) : '';
}

String semesterLabel(DateTime date) {
  final s = date.month <= 6 ? '1º' : '2º';
  return '$s Semestre/${date.year}';
}

String currentCycleLabel() => '${DateTime.now().year}';

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int daysUntil(DateTime target) {
  final now = DateTime.now();
  return target.difference(DateTime(now.year, now.month, now.day)).inDays;
}