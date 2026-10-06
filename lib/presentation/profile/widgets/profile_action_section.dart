import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gp1/app/navigation/e_app_route.dart';
import 'package:gp1/data/models/dto/update_profile_request.dart';
import 'package:gp1/data/models/user.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:gp1/presentation/app/cubit/app_cubit.dart';
import 'package:gp1/presentation/auth/cubit/auth_cubit.dart';
import 'package:gp1/presentation/profile/cubit/profile_cubit.dart';
import 'package:gp1/presentation/widgets/app_text_field.dart';
import 'package:solar_icons/solar_icons.dart';

class ProfileActionSection extends StatefulWidget {
  const ProfileActionSection({super.key});

  @override
  State<ProfileActionSection> createState() => _ProfileActionSectionState();
}

class _ProfileActionSectionState extends State<ProfileActionSection> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _github = TextEditingController();
  final _figma = TextEditingController();
  final _swagger = TextEditingController();

  /// The user the controllers were last filled from, to refill them when it changes.
  User? _loaded;

  List<TextEditingController> get _controllers => [_name, _phone, _github, _figma, _swagger];

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _fill(User user) {
    _loaded = user;
    _name.text = user.name ?? '';
    _phone.text = user.phone ?? '';
    _github.text = user.github ?? '';
    _figma.text = user.figma ?? '';
    _swagger.text = user.swagger ?? '';
  }

  UpdateProfileRequest _changes(User user) => ProfileCubit.changes(
    user,
    name: _name.text,
    phone: _phone.text,
    github: _github.text,
    figma: _figma.text,
    swagger: _swagger.text,
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final user = state.user;
        // Fill the form from the saved profile, on first show and when it changes.
        if (user != null && user != _loaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || user == _loaded) return;
            // Keep text that was typed but not saved when only another part of the profile
            // changed, such as the avatar.
            final loaded = _loaded;
            if (loaded == null || _changes(loaded).hasNoChanges) {
              _fill(user);
            } else {
              _loaded = user;
            }
          });
        }
        final isSaving = context.select((ProfileCubit cubit) => cubit.state.isSaving);
        final canSave = user != null && !isSaving && !_changes(user).hasNoChanges;

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
                    // ── Account (fixed) ──
                    const _SectionLabel(label: 'Account'),
                    AppTextField(
                      value: user?.username ?? '',
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(SolarIconsOutline.user, size: 20),
                        helperText: 'The username cannot be changed',
                      ),
                    ),
                    AppTextField(
                      value: user?.email ?? '',
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(SolarIconsOutline.letter, size: 20),
                        helperText: 'The email cannot be changed',
                      ),
                    ),

                    // ── Editable fields ──
                    const _SectionLabel(label: 'Personal Information'),
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(SolarIconsOutline.userId, size: 20),
                      ),
                    ),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(SolarIconsOutline.phone, size: 20),
                      ),
                    ),
                    const _SectionLabel(label: 'Links'),
                    TextFormField(
                      controller: _github,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'GitHub',
                        prefixIcon: Icon(SolarIconsOutline.globus, size: 20),
                      ),
                    ),
                    TextFormField(
                      controller: _figma,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Figma',
                        prefixIcon: Icon(SolarIconsOutline.palette, size: 20),
                      ),
                    ),
                    TextFormField(
                      controller: _swagger,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Swagger',
                        prefixIcon: Icon(SolarIconsOutline.code, size: 20),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: canSave
                          ? () => context.read<ProfileCubit>().save(_changes(user))
                          : null,
                      icon: isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(SolarIconsOutline.diskette),
                      label: const Text('Save changes'),
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
