import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gp1/core/di/injection.dart';
import 'package:gp1/core/utils/extensions/snack_bar_extension.dart';
import 'package:gp1/presentation/change_password/cubit/change_password_cubit.dart';
import 'package:gp1/presentation/widgets/app_text_field.dart';
import 'package:gp1/presentation/widgets/my_app_bar.dart';
import 'package:solar_icons/solar_icons.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChangePasswordCubit>(),
      child: BlocListener<ChangePasswordCubit, ChangePasswordState>(
        listener: (context, state) {
          context.handleFailure(state.failure);
          if (state.isSuccess) {
            context.pop();
            context.showSnackBar('Password changed successfully.', type: SnackBarType.success);
          }
        },
        child: const ChangePasswordContent(),
      ),
    );
  }
}

class ChangePasswordContent extends StatefulWidget {
  const ChangePasswordContent({super.key});

  @override
  State<ChangePasswordContent> createState() => _ChangePasswordContentState();
}

class _ChangePasswordContentState extends State<ChangePasswordContent> {
  final _formKey = GlobalKey<FormState>();

  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  void _toggleOldPasswordVisibility() {
    setState(() {
      _isOldPasswordVisible = !_isOldPasswordVisible;
    });
  }

  void _toggleNewPasswordVisibility() {
    setState(() {
      _isNewPasswordVisible = !_isNewPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChangePasswordCubit>();
    final oldPassword = context.select((ChangePasswordCubit cubit) => cubit.state.oldPassword);
    final newPassword = context.select((ChangePasswordCubit cubit) => cubit.state.newPassword);
    final confirmPassword = context.select(
      (ChangePasswordCubit cubit) => cubit.state.confirmPassword,
    );

    return Scaffold(
      appBar: const MyAppBar(title: Text('Change Password')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppTextField(
                          value: oldPassword,
                          onChanged: cubit.updateOldPassword,
                          obscureText: !_isOldPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            suffixIcon: IconButton(
                              onPressed: _toggleOldPasswordVisibility,
                              icon: Icon(
                                _isOldPasswordVisible
                                    ? SolarIconsOutline.eyeClosed
                                    : SolarIconsOutline.eye,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter current password.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          value: newPassword,
                          obscureText: !_isNewPasswordVisible,
                          onChanged: cubit.updateNewPassword,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            suffixIcon: IconButton(
                              onPressed: _toggleNewPasswordVisibility,
                              icon: Icon(
                                _isNewPasswordVisible
                                    ? SolarIconsOutline.eyeClosed
                                    : SolarIconsOutline.eye,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter new password.';
                            }
                            if (value == oldPassword) {
                              return 'New password must be different from current password.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        AppTextField(
                          value: confirmPassword,
                          obscureText: !_isConfirmPasswordVisible,
                          onChanged: cubit.updateConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
                            suffixIcon: IconButton(
                              onPressed: _toggleConfirmPasswordVisibility,
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? SolarIconsOutline.eyeClosed
                                    : SolarIconsOutline.eye,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your new password.';
                            }
                            if (value != newPassword) {
                              return 'Passwords do not match.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                context.read<ChangePasswordCubit>().changePassword();
                              }
                            },
                            child: const Text('Reset Password'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
