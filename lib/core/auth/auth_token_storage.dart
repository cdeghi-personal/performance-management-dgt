import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final authTokenStorageProvider = Provider<AuthTokenStorage>((_) => AuthTokenStorage());

/// Persistência local da sessão (MVP: sem expiração, usuário fica logado até logout).
class AuthTokenStorage {
  final _storage = const FlutterSecureStorage();

  static const _keyUsername = 'session_username';
  static const _keyUserId = 'session_user_id';
  static const _keyDisplayName = 'session_display_name';

  Future<void> saveSession({
    required String username,
    String? userId,
    String? displayName,
  }) async {
    await Future.wait([
      _storage.write(key: _keyUsername, value: username),
      if (userId != null) _storage.write(key: _keyUserId, value: userId),
      if (displayName != null) _storage.write(key: _keyDisplayName, value: displayName),
    ]);
  }

  Future<bool> hasSession() async {
    final v = await _storage.read(key: _keyUsername);
    return v != null && v.isNotEmpty;
  }

  Future<String?> getUsername() => _storage.read(key: _keyUsername);
  Future<String?> getUserId() => _storage.read(key: _keyUserId);
  Future<String?> getDisplayName() => _storage.read(key: _keyDisplayName);

  Future<void> clear() => _storage.deleteAll();
}