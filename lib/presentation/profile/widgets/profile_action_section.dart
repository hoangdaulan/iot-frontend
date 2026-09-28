import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gp1/app/navigation/e_app_route.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:gp1/presentation/app/cubit/app_cubit.dart';
import 'package:gp1/presentation/auth/cubit/auth_cubit.dart';
import 'package:gp1/presentation/widgets/app_text_field.dart';
import 'package:solar_icons/solar_icons.dart';

class ProfileActionSection extends StatelessWidget {
  const ProfileActionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  spacing: 12,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Editable Fields ──
                    const _SectionLabel(label: 'Contact Information'),
                    AppTextField(
                      value: state.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(SolarIconsOutline.phone, size: 20),
                      ),
                      onChanged: cubit.updatePhone,
                    ),
                    const _SectionLabel(label: 'Social Links'),
                    AppTextField(
                      value: state.github,
                      decoration: const InputDecoration(
                        labelText: 'GitHub',
                        prefixIcon: Icon(SolarIconsOutline.globus, size: 20),
                      ),
                      onChanged: cubit.updateGithub,
                    ),
                    AppTextField(
                      value: state.figma,
                      decoration: const InputDecoration(
                        labelText: 'Figma',
                        prefixIcon: Icon(SolarIconsOutline.palette, size: 20),
                      ),
                      onChanged: cubit.updateFigma,
                    ),
                    const SizedBox(height: 8),

                    // ── Actions ──
                    const _SectionLabel(label: 'Actions'),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.push('${EAppRoute.account.path}/${EAppRoute.changePassword.path}');
                      },
                      icon: const Icon(SolarIconsOutline.lock),
                      label: const Text('Change Password'),
                    ),
                    const _LogoutButton(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ColorName.labelSecondary,
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Confirm Logout'),
              content: const Text('Are you sure you want to log out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: TextButton.styleFrom(foregroundColor: ColorName.red),
                  child: const Text('Logout'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );

        if (shouldLogout == true && context.mounted) {
          context.read<AuthCubit>().logout();
        }
      },
      icon: const Icon(SolarIconsOutline.logout_2),
      label: const Text('Logout'),
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorName.red.withValues(alpha: 0.8),
        side: BorderSide(color: ColorName.red.withValues(alpha: 0.8)),
      ),
    );
  }
}
