import 'package:freezed_annotation/freezed_annotation.dart';

part 'paged_list.freezed.dart';
part 'paged_list.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class PagedList<T> with _$PagedList<T> {
  const factory PagedList({
    @Default([]) List<T> data,
    @Default(1) int page,
    @Default(20) int pageSize,
    @Default(1) int pageCounts,
  }) = _PagedList<T>;

  factory PagedList.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$PagedListFromJson(json, fromJsonT);
}
