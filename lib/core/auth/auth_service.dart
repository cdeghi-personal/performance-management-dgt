import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../error/sydle_exception.dart';
import '../../features/auth/domain/auth_model.dart';

final authServiceProvider = Provider<AuthService>((_) => AuthService());

/// Lida exclusivamente com os endpoints de autenticação do SYDLE ONE.
/// Usa instância própria do Dio (não compartilhada com SydleClient).
class AuthService {
  late final Dio _dio;

  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.authBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    ));
    _dio.interceptors.add(LogInterceptor(
      requestHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  /// GET /sys/auth/signIn com Basic auth (credenciais do usuário).
  Future<AuthSession> signIn(String login, String password) async {
    final credentials = base64Encode(utf8.encode('$login:$password'));
    try {
      final resp = await _dio.get(
        '/sys/auth/signIn',
        options: Options(headers: {'Authorization': 'Basic $credentials'}),
      );
      return AuthSession.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        throw SydleAuthException('Usuário ou senha inválidos. [HTTP $status]');
      }
      throw SydleException(
        '[HTTP ${status ?? '?'}] ${e.response?.data?.toString() ?? e.message ?? 'Erro de conexão'}',
        statusCode: status,
      );
    }
  }

  /// GET /sys/auth/signOut com Bearer token. Best-effort — ignora erros.
  Future<void> signOut(String token) async {
    try {
      await _dio.get(
        '/sys/auth/signOut',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (_) {
      // best-effort: sessão local já será apagada independentemente
    }
  }
}
