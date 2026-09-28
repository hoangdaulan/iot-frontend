import 'package:freezed_annotation/freezed_annotation.dart';

class DateTimeConverter implements JsonConverter<DateTime, String> {
  /// Convert DateTime to UTC ISO8601 string
  ///
  /// ```dart
  /// // For each DateTime field
  /// @DateTimeConverter()
  /// DateTime createdAt
  ///
  /// // For JSONSerializable class
  /// @JsonSerializable(converters: [DateTimeConverter()])
  /// class Model {
  ///   DateTime? createdAt;
  ///   DateTime? updatedAt;
  /// }
  ///
  /// // For freezed model, add to factory constructor
  /// @JsonSerializable(converters: [DateTimeConverter()])
  /// const factory Model({
  ///   DateTime? createdAt,
  ///   DateTime? updatedAt,
  /// }) = _Model;
  /// ```
  const DateTimeConverter();

  @override
  DateTime fromJson(String json) {
    return DateTime.parse(json).toLocal();
  }

  @override
  String toJson(DateTime time) {
    return time.toUtc().toIso8601String();
  }
}
