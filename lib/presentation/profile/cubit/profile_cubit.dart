import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/dto/update_profile_request.dart';
import 'package:gp1/data/models/user.dart';
import 'package:gp1/data/repositories/auth_repository.dart';
import 'package:gp1/presentation/auth/cubit/auth_cubit.dart';

class ProfileState {
  const ProfileState({
    this.isSaving = false,
    this.isUploadingAvatar = false,
    this.message,
    this.failure,
  });

  final bool isSaving;
  final bool isUploadingAvatar;

  /// A success message to show once; the next state clears it.
  final String? message;
  final Failure? failure;

  bool get isBusy => isSaving || isUploadingAvatar;
}

/// Edits the signed-in user's profile and avatar. Every saved profile goes back to [AuthCubit],
/// which feeds the rest of the app.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._authRepository, this._authCubit) : super(const ProfileState());

  final AuthRepository _authRepository;
  final AuthCubit _authCubit;

  /// What differs between [user] and the edited values; the email and username are not editable.
  /// Empty text counts as "no value", like a missing field.
  static UpdateProfileRequest changes(
    User user, {
    required String name,
    required String phone,
    required String github,
    required String figma,
    required String swagger,
  }) {
    String? changed(String? current, String edited) =>
        (current ?? '') == edited.trim() ? null : edited.trim();
    return UpdateProfileRequest(
      name: changed(user.name, name),
      phone: changed(user.phone, phone),
      github: changed(user.github, github),
      figma: changed(user.figma, figma),
      swagger: changed(user.swagger, swagger),
    );
  }

  /// Fetches the profile from the backend, so the form shows what is stored there.
  Future<void> load() async {
    final result = await _authRepository.getProfile();
    switch (result) {
      case Success(data: final user):
        _authCubit.updateUser(user);
      case Failure():
        emit(ProfileState(failure: result));
    }
  }

  Future<void> save(UpdateProfileRequest request) async {
    if (state.isBusy || request.hasNoChanges) return;

    emit(const ProfileState(isSaving: true));
    final result = await _authRepository.updateProfile(request);
    switch (result) {
      case Success(data: final user):
        _authCubit.updateUser(user);
        emit(const ProfileState(message: 'Profile updated'));
      case Failure():
        emit(ProfileState(failure: result));
    }
  }

  Future<void> uploadAvatar(Uint8List bytes, String filename) async {
    if (state.isBusy) return;

    emit(const ProfileState(isUploadingAvatar: true));
    final result = await _authRepository.uploadAvatar(bytes: bytes, filename: filename);
    switch (result) {
      case Success(data: final user):
        _authCubit.updateUser(user);
        emit(const ProfileState(message: 'Avatar updated'));
      case Failure():
        emit(ProfileState(failure: result));
    }
  }
}
