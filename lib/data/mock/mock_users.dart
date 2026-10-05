import 'package:gp1/data/models/user.dart';

const mockUser = User(
  id: 1,
  username: 'leo_nguyen',
  email: 'leo.nguyen@iot-project.com',
  phone: '+84 912 345 678',
  role: UserRole.admin,
  github: 'https://github.com/leo-nguyen',
  figma: 'https://figma.com/@leo-nguyen',
);

/// Credentials pre-filled on the login form while the backend is mocked.
const mockLoginUsername = 'admin';
const mockLoginPassword = '123456';

const mockAccessToken = 'mock-access-token';
