import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/core/di/injection.dart';
import 'package:gp1/core/utils/extensions/snack_bar_extension.dart';
import 'package:gp1/presentation/profile/cubit/profile_cubit.dart';
import 'package:gp1/presentation/profile/widgets/profile_action_section.dart';
import 'package:gp1/presentation/profile/widgets/profile_footer.dart';
import 'package:gp1/presentation/widgets/my_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileCubit>()..load(),
      child: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state.message case final message?) {
            context.showSnackBar(message, type: SnackBarType.success);
          }
          context.handleFailure(state.failure);
        },
        child: const Scaffold(
          appBar: MyAppBar(title: Text('Account')),
          body: CustomScrollView(slivers: [ProfileActionSection(), ProfileFooter()]),
        ),
      ),
    );
  }
}
