import 'package:flutter/material.dart';
import 'package:gp1/presentation/widgets/developer_attribution.dart';

class ProfileFooter extends StatelessWidget {
  const ProfileFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const SliverFillRemaining(
      child: Align(alignment: Alignment.bottomCenter, child: DeveloperAttribution()),
    );
  }
}
