import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/data/local/shared_preferences_local_data_base.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saves, reads and clears the access token', () async {
    final storage = SharedPreferencesLocalDataBase();

    expect(await storage.getAccessToken(), isNull);

    await storage.saveAccessToken('jwt-token');
    expect(await storage.getAccessToken(), 'jwt-token');

    await storage.clearTokens();
    expect(await storage.getAccessToken(), isNull);
  });

  test('saveTokens stores both tokens and clearTokens removes both', () async {
    final storage = SharedPreferencesLocalDataBase();

    await storage.saveTokens('access', 'refresh');
    expect(await storage.getAccessToken(), 'access');
    expect(await storage.getRefreshToken(), 'refresh');

    await storage.clearTokens();
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
  });
}
