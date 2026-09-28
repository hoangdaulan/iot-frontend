import 'package:flutter/foundation.dart';
import 'package:gp1/core/auth/auth_cubit_base.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthNotifier extends ChangeNotifier {
  final AuthCubitBase _authCubit;

  AuthNotifier(this._authCubit) {
    _authCubit.stream.listen((_) => notifyListeners());
  }

  bool get isAuthenticated => _authCubit.state.isAuthenticated;
}
