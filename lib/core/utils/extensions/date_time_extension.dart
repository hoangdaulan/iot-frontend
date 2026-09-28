import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  String toFormatString({String pattern = 'dd/MM/yyyy'}) {
    final formatter = DateFormat(pattern);
    return formatter.format(this);
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day + 1).subtract(const Duration(milliseconds: 1));
}

extension DateTimeRangeExtension on DateTimeRange {
  String toFormatString() {
    if (start.isSameDay(end)) {
      return start.toFormatString(pattern: 'dd/MM/yyyy');
    }
    if (start.month == end.month && start.year == end.year) {
      return '${DateFormat('dd').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}';
    } else if (start.year == end.year) {
      return '${DateFormat('dd/MM').format(start)} - ${DateFormat('dd/MM/yy').format(end)}';
    }
    return '${DateFormat('dd/MM/yy').format(start)} - ${DateFormat('dd/MM/yy').format(end)}';
  }
}
