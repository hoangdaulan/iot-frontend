import 'package:gp1/core/base/local_data_base.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Token storage backed by `shared_preferences` (`localStorage` on Flutter Web). Only tokens are
/// stored here; credentials never are.
class SharedPreferencesLocalDataBase implements LocalDataBase {
  static const _accessTokenKey = 'auth.accessToken';
  static const _refreshTokenKey = 'auth.refreshToken';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<void> saveAccessToken(String token) async {
    await (await _prefs).setString(_accessTokenKey, token);
  }

  @override
  Future<String?> getAccessToken() async => (await _prefs).getString(_accessTokenKey);

  @override
  Future<void> saveRefreshToken(String token) async {
    await (await _prefs).setString(_refreshTokenKey, token);
  }

  @override
  Future<String?> getRefreshToken() async => (await _prefs).getString(_refreshTokenKey);

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    final prefs = await _prefs;
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}
