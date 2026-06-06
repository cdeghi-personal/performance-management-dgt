import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final sessionManagerProvider = Provider<SessionManager>((_) => SessionManager());

class SessionManager {
  final _storage = const FlutterSecureStorage();

  static const _keyToken         = 'sess_access_token';
  static const _keyExp           = 'sess_token_exp';
  static const _keyName          = 'sess_name';
  static const _keyLogin         = 'sess_login';
  static const _keyCode          = 'sess_code';
  static const _keySessionId     = 'sess_session_id';
  static const _keyColaboradorId = 'sess_colaborador_id';
  static const _keyProfile       = 'sess_profile';

  Future<void> saveToken({
    required String accessToken,
    required int expMs,
    required String name,
    required String login,
    required String code,
    String? sessionId,
  }) async {
    // Escrita sequencial — Future.wait() concorrente causa OperationError
    // no Web Crypto API do Flutter Web (race na inicialização da chave).
    await _storage.write(key: _keyToken, value: accessToken);
    await _storage.write(key: _keyExp,   value: expMs.toString());
    await _storage.write(key: _keyName,  value: name);
    await _storage.write(key: _keyLogin, value: login);
    await _storage.write(key: _keyCode,  value: code);
    if (sessionId != null) {
      await _storage.write(key: _keySessionId, value: sessionId);
    }
  }

  Future<void> saveProfile({
    required String colaboradorId,
    required String profile,
  }) async {
    await _storage.write(key: _keyColaboradorId, value: colaboradorId);
    await _storage.write(key: _keyProfile,       value: profile);
  }

  /// Returns true only when a non-expired token AND a colaboradorId are present.
  Future<bool> hasValidSession() async {
    final token = await _storage.read(key: _keyToken);
    if (token == null || token.isEmpty) return false;
    final expStr = await _storage.read(key: _keyExp);
    if (expStr == null) return false;
    final exp = int.tryParse(expStr) ?? 0;
    if (DateTime.now().millisecondsSinceEpoch >= exp) return false;
    final colabId = await _storage.read(key: _keyColaboradorId);
    return colabId != null && colabId.isNotEmpty;
  }

  Future<String?> getToken()         => _storage.read(key: _keyToken);
  Future<String?> getLogin()         => _storage.read(key: _keyLogin);
  Future<String?> getName()          => _storage.read(key: _keyName);
  Future<String?> getCode()          => _storage.read(key: _keyCode);
  Future<String?> getSessionId()     => _storage.read(key: _keySessionId);
  Future<String?> getColaboradorId() => _storage.read(key: _keyColaboradorId);
  Future<String?> getProfile()       => _storage.read(key: _keyProfile);

  Future<void> clear() => _storage.deleteAll();
}
