import 'package:gp1/data/models/user.dart';

/// A signed-in user with every profile field filled in.
const sampleUser = User(
  id: 1,
  name: 'Leo Nguyen',
  username: 'leo_nguyen',
  email: 'leo.nguyen@iot-project.com',
  phone: '+84 912 345 678',
  role: UserRole.admin,
  github: 'https://github.com/leo-nguyen',
  figma: 'https://figma.com/@leo-nguyen',
  swagger: 'http://localhost:8080/swagger/index.html',
);
