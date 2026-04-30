import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/sydle_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/auth/auth_token_storage.dart';
import '../domain/auth_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    client: ref.read(sydleClientProvider),
    storage: ref.read(authTokenStorageProvider),
  );
});

class AuthRepository {
  final SydleClient _client;
  final AuthTokenStorage _storage;

  AuthRepository({required SydleClient client, required AuthTokenStorage storage})
      : _client = client,
        _storage = storage;

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final resp = await _client.post(ApiConstants.authLogin, data: {
      'email': email,
      'password': password,
    });

    final data = resp.data as Map<String, dynamic>;
    await _storage.save(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      userId: data['user']['id'] as String,
    );

    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiConstants.authLogout);
    } finally {
      await _storage.clear();
    }
  }

  Future<bool> isLoggedIn() => _storage.hasToken();
}