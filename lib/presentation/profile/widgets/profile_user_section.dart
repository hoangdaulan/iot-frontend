import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/app/config/app_config.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:gp1/presentation/app/cubit/app_cubit.dart';
import 'package:gp1/presentation/profile/cubit/profile_cubit.dart';
import 'package:solar_icons/solar_icons.dart';

class ProfileUserSection extends StatelessWidget {
  const ProfileUserSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                // Avatar
                _Avatar(avatar: state.user?.avatar),
                const SizedBox(height: 16),
                Text(
                  state.user?.displayName ?? '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  state.user?.email ?? '',
                  style: const TextStyle(fontSize: 14, color: ColorName.labelSecondary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorName.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.user?.role.label ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ColorName.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatar});

  final String? avatar;

  static const _size = 80.0;

  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    cubit.uploadAvatar(await file.readAsBytes(), file.name);
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = context.select((ProfileCubit cubit) => cubit.state.isUploadingAvatar);
    final url = (avatar ?? '').isEmpty ? null : AppConfig.resolveUrl(avatar!);

    final placeholder = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorName.primary, Color(0xFF33A0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(SolarIconsBold.user, size: 40, color: ColorName.white),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: ColorName.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: url == null
              ? placeholder
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => placeholder,
                  errorWidget: (_, _, _) => placeholder,
                ),
        ),
        if (isUploading)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: ColorName.white),
                ),
              ),
            ),
          ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Material(
            color: ColorName.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: ColorName.gray5),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: isUploading ? null : () => _pick(context),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(SolarIconsOutline.camera, size: 16, color: ColorName.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
