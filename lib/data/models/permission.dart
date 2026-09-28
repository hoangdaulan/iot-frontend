import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission.freezed.dart';
part 'permission.g.dart';

@freezed
abstract class Permission with _$Permission {
  const factory Permission({
    @Default('') String id,
    @Default('') String code,
    @Default('') String name,
  }) = _Permission;

  const Permission._();

  factory Permission.fromJson(Map<String, dynamic> json) => _$PermissionFromJson(json);

  EPermission get ePermission => EPermission.fromJson(code);
}

enum EPermission {
  unknown(null);

  final String? value;

  const EPermission(this.value);

  String? toJson() => value;

  factory EPermission.fromJson(String? json) {
    return EPermission.values.firstWhere((e) => e.value == json, orElse: () => EPermission.unknown);
  }
}

extension PermissionListExtension on List<Permission> {
  List<EPermission> toEnum() => map((p) => p.ePermission).toList();
}
