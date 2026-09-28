import 'package:flutter/material.dart';
import 'package:gp1/presentation/profile/widgets/profile_action_section.dart';
import 'package:gp1/presentation/profile/widgets/profile_footer.dart';
import 'package:gp1/presentation/profile/widgets/profile_user_section.dart';
import 'package:gp1/presentation/widgets/my_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MyAppBar(title: Text('Account')),
      body: CustomScrollView(
        slivers: [ProfileUserSection(), ProfileActionSection(), ProfileFooter()],
      ),
    );
  }
}
