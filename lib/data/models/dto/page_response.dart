import 'package:freezed_annotation/freezed_annotation.dart';

part 'page_response.freezed.dart';
part 'page_response.g.dart';

/// Paged list envelope used by `GET /api/devices/control-history`. `page` is 0-based.
@Freezed(genericArgumentFactories: true)
abstract class PageResponse<T> with _$PageResponse<T> {
  const factory PageResponse({
    @Default([]) List<T> content,
    @Default(0) int page,
    @Default(20) int size,
    @Default(0) int totalElements,
    @Default(0) int totalPages,
  }) = _PageResponse<T>;

  factory PageResponse.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$PageResponseFromJson(json, fromJsonT);
}
