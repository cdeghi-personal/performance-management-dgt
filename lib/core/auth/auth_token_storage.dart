import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  return AuthTokenStorage();
});

class AuthTokenStorage {
  final _storage = const FlutterSecureStorage();

  static const _accessKey = 'sydle_access_token';
  static const _refreshKey = 'sydle_refresh_token';
  static const _userIdKey = 'sydle_user_id';

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await Future.wait([
      _storage.write(key: _accessKey, value: accessToken),
      _storage.write(key: _refreshKey, value: refreshToken),
      _storage.write(key: _userIdKey, value: userId),
    ]);
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: _accessKey);
    return token != null;
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessKey);
  Future<String?> getUserId() => _storage.read(key: _userIdKey);

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
      _storage.delete(key: _userIdKey),
    ]);
  }
}