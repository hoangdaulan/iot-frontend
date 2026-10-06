import 'package:json_annotation/json_annotation.dart';

part 'update_profile_request.g.dart';

/// Body of `PATCH /api/auth/profile`, limited to the fields the Profile screen edits (the email
/// and username cannot be changed). Null fields are omitted, so only changed fields are sent.
@JsonSerializable(createFactory: false)
class UpdateProfileRequest {
  const UpdateProfileRequest({this.name, this.phone, this.github, this.figma, this.swagger});

  final String? name;
  final String? phone;
  final String? github;
  final String? figma;
  final String? swagger;

  /// Whether nothing is to be updated.
  @JsonKey(includeToJson: false)
  bool get hasNoChanges =>
      name == null && phone == null && github == null && figma == null && swagger == null;

  Map<String, dynamic> toJson() => _$UpdateProfileRequestToJson(this);
}
