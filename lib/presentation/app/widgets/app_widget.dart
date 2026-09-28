import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/core/utils/extensions/snack_bar_extension.dart';
import 'package:gp1/presentation/app/cubit/app_cubit.dart';
import 'package:gp1/presentation/auth/cubit/auth_cubit.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({super.key, required this.navigatorKey, required this.child});
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAuthStateChanges(context.read<AuthCubit>().state);
    });
  }

  void _handleAuthStateChanges(AuthState state) async {
    if (state.isAuthenticated) {
      await context.read<AppCubit>().load();
    } else {
      await context.read<AppCubit>().clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) => _handleAuthStateChanges(state),
      child: BlocListener<AppCubit, AppState>(
        listener: (context, state) => context.handleFailure(state.failure),
        child: widget.child,
      ),
    );
  }
}
