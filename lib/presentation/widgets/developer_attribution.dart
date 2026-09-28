import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:gp1/presentation/app/cubit/app_cubit.dart';
import 'package:gp1/presentation/app/models/app_info.dart';
import 'package:url_launcher/url_launcher.dart';

class DeveloperAttribution extends StatelessWidget {
  const DeveloperAttribution({super.key, this.fontSize = 14});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Designed by ',
                  style: TextStyle(color: ColorName.labelPrimary, fontSize: fontSize),
                ),
                TextSpan(
                  text: 'kaizengo.vn',
                  style: TextStyle(color: const Color(0xffdd3333), fontSize: fontSize),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launchUrl(
                        Uri.parse('https://kaizengo.vn'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                ),
              ],
            ),
          ),
          BlocSelector<AppCubit, AppState, AppInfo>(
            selector: (state) => state.appInfo,
            builder: (context, state) {
              return Text(
                'MyIoT ${state.buildName}',
                style: const TextStyle(fontSize: 10, color: ColorName.labelSecondary),
              );
            },
          ),
        ],
      ),
    );
  }
}
