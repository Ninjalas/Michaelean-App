// Small date helpers, so we don't need the intl package yet.

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
];
const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

/// "20 October" — shown with [weekdayName] in muted text: "20 October / Tuesday"
String formatDayMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';

String weekdayName(DateTime d) => _weekdays[d.weekday - 1];

/// "20 October 2026"
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// "Just now", "5m ago", "2h ago", "3d ago", then a date.
String formatTimeAgo(DateTime time, DateTime now) {
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatDate(time);
}

/// "9:00 AM"
String formatTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}

/// "Today", "Tomorrow", or "Thursday" (within a week), else a date.
String formatDayLabel(DateTime d, DateTime now) {
  final days = DateTime(d.year, d.month, d.day)
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  if (days > 1 && days < 7) return _weekdays[d.weekday - 1];
  return formatDate(d);
}

String greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 18) return 'Good afternoon';
  return 'Good evening';
}

/// "Mon", "Tue", … for DateTime.monday … DateTime.sunday.
String weekdayShort(int weekday) => _weekdays[weekday - 1].substring(0, 3);

/// "7:30 – 9:00 AM" for a class's start and end, in minutes after midnight.
String formatMinutesRange(int start, int end) {
  final today = DateTime(2000);
  return '${formatTime(today.add(Duration(minutes: start)))} – '
      '${formatTime(today.add(Duration(minutes: end)))}';
}
