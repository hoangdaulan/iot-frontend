enum TimePrecision {
  day('Ngày', 'dd/MM/yyyy'),
  hour('Giờ', 'dd/MM/yyyy HH:00'),
  minute('Phút', 'dd/MM/yyyy HH:mm'),
  second('Giây', 'dd/MM/yyyy HH:mm:ss');

  final String label;
  final String formatPattern;

  const TimePrecision(this.label, this.formatPattern);

  DateTime truncate(DateTime dt) {
    switch (this) {
      case TimePrecision.day:
        return DateTime(dt.year, dt.month, dt.day);
      case TimePrecision.hour:
        return DateTime(dt.year, dt.month, dt.day, dt.hour);
      case TimePrecision.minute:
        return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
      case TimePrecision.second:
        return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
    }
  }
}
