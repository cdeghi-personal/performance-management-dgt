import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final authTokenStorageProvider = Provider<AuthTokenStorage>((_) => AuthTokenStorage());

class AuthTokenStorage {
  final _storage = const FlutterSecureStorage();

  static const _keyUsername      = 'session_username';
  static const _keyColaboradorId = 'session_colaborador_id';
  static const _keyDisplayName   = 'session_display_name';
  static const _keyProfile       = 'session_profile';

  Future<void> saveSession({
    required String username,
    required String colaboradorId,
    required String name,
    required String profile,
  }) async {
    await Future.wait([
      _storage.write(key: _keyUsername,      value: username),
      _storage.write(key: _keyColaboradorId, value: colaboradorId),
      _storage.write(key: _keyDisplayName,   value: name),
      _storage.write(key: _keyProfile,       value: profile),
    ]);
  }

  Future<bool> hasSession() async {
    final v = await _storage.read(key: _keyColaboradorId);
    return v != null && v.isNotEmpty;
  }

  Future<String?> getUsername()      => _storage.read(key: _keyUsername);
  Future<String?> getColaboradorId() => _storage.read(key: _keyColaboradorId);
  Future<String?> getDisplayName()   => _storage.read(key: _keyDisplayName);
  Future<String?> getProfile()       => _storage.read(key: _keyProfile);

  Future<void> clear() => _storage.deleteAll();
}
