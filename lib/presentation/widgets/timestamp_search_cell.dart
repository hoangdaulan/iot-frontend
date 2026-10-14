import 'package:flutter/material.dart';
import 'package:gp1/app/constants/app_constants.dart';
import 'package:gp1/core/utils/extensions/date_time_extension.dart';

/// A table cell showing [timestamp] with an outlined button at its end that hands the shown text to [onSearch], so
/// the row's time can be searched with one tap. The button is disabled when [onSearch] is null.
class TimestampSearchCell extends StatelessWidget {
  const TimestampSearchCell({super.key, required this.timestamp, this.onSearch});

  final DateTime timestamp;
  final ValueChanged<String>? onSearch;

  @override
  Widget build(BuildContext context) {
    final text = timestamp.toFormatString(pattern: AppConstants.dateTimeFormat);
    return Row(
      children: [
        Expanded(
          child: Center(child: Text(text, style: const TextStyle(fontSize: 13))),
        ),
        Tooltip(
          message: 'Search this time',
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(36, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onSearch == null ? null : () => onSearch!(text),
            child: const Icon(Icons.manage_search, size: 18),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
