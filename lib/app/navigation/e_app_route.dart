enum EAppRoute {
  login(path: '/login'),
  register(path: '/register'),
  log(path: '/log'),

  dashboard(path: '/'),
  sensors(path: '/sensors'),
  controlHistory(path: '/control-history'),
  account(path: '/account'),
  changePassword(path: 'change-password');

  final String path;
  const EAppRoute({required this.path});
}

final publicPaths = [EAppRoute.login.path, EAppRoute.register.path];
