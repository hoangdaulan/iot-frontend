// Search helpers shared by the mock repositories, mirroring the backend.

final _timePrefix = RegExp(
  r'^(\d{4})(?:[/-](\d{1,2})(?:[/-](\d{1,2})(?:[ T](\d{1,2})(?::(\d{1,2})(?::(\d{1,2}))?)?)?)?)?$',
);

/// `[start, end)` named by a leading part of `yyyy/MM/dd HH:mm:ss`, in local time.
(DateTime, DateTime)? mockTimePrefixRange(String text) {
  final m = _timePrefix.firstMatch(text);
  if (m == null) return null;
  final parts = [for (var i = 1; i <= 6; i++) m.group(i) == null ? null : int.parse(m.group(i)!)];
  final given = parts.takeWhile((p) => p != null).length;
  int part(int i, int fallback) => parts[i] ?? fallback;
  final start = DateTime(parts[0]!, part(1, 1), part(2, 1), part(3, 0), part(4, 0), part(5, 0));
  final end = switch (given) {
    1 => DateTime(start.year + 1),
    2 => DateTime(start.year, start.month + 1),
    3 => DateTime(start.year, start.month, start.day + 1),
    4 => DateTime(start.year, start.month, start.day, start.hour + 1),
    5 => DateTime(start.year, start.month, start.day, start.hour, start.minute + 1),
    _ => start.add(const Duration(seconds: 1)),
  };
  return (start, end);
}
