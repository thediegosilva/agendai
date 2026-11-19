/// Formatação pt-BR sem depender de pacotes de localização.
library;

const weekdayShort = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
const weekdayLong = [
  'Domingo',
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
];
const monthShort = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun', //
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// 4500 → "R$ 45,00"
String formatMoney(int cents) {
  final reais = (cents ~/ 100).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'R\$ $reais,${_two(cents % 100)}';
}

/// 90 → "1h30", 45 → "45 min"
String formatDuration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final m = minutes % 60;
  return m == 0 ? '${minutes ~/ 60}h' : '${minutes ~/ 60}h${_two(m)}';
}

/// 540 → "09:00"
String formatMinute(int minute) => '${_two(minute ~/ 60)}:${_two(minute % 60)}';

String formatTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

/// DateTime.weekday (1 = seg ... 7 = dom) → índice 0 = domingo.
int weekdayIndex(DateTime d) => d.weekday % 7;

/// "Qui, 20 nov"
String formatDayShort(DateTime d) =>
    '${weekdayShort[weekdayIndex(d)]}, ${d.day} ${monthShort[d.month - 1]}';

/// "Hoje", "Amanhã" ou "Qui, 20 nov"
String formatRelativeDay(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Amanhã';
  return formatDayShort(d);
}

/// Data no formato da API: YYYY-MM-DD.
String isoDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

const monthLong = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', //
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

/// "Quinta, 19 de novembro"
String formatDayLong(DateTime d) =>
    '${weekdayLong[weekdayIndex(d)]}, ${d.day} de ${monthLong[d.month - 1]}';

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "21987654321" → "(21) 98765-4321"; outros formatos voltam como vieram.
String formatPhone(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.length == 11) {
    return '(${d.substring(0, 2)})\u00A0${d.substring(2, 7)}-${d.substring(7)}';
  }
  if (d.length == 10) {
    return '(${d.substring(0, 2)})\u00A0${d.substring(2, 6)}-${d.substring(6)}';
  }
  return raw;
}
