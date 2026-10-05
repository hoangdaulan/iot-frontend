import 'package:json_annotation/json_annotation.dart';

part 'update_profile_request.g.dart';

/// Body of `PATCH /api/auth/profile`, limited to the fields the Profile screen edits. Null
/// fields are omitted, so only changed fields are sent.
@JsonSerializable(createFactory: false)
class UpdateProfileRequest {
  const UpdateProfileRequest({this.phone, this.github, this.figma});

  final String? phone;
  final String? github;
  final String? figma;

  Map<String, dynamic> toJson() => _$UpdateProfileRequestToJson(this);
}
