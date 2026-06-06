import 'dart:async';
import 'package:dio/dio.dart';
import 'session_manager.dart';

/// Stream global emitido quando o servidor retorna 401 ou 403.
/// AuthNotifier subscreve a este stream no build() e faz logout local.
final _authErrorController = StreamController<void>.broadcast();
Stream<void> get authErrorStream => _authErrorController.stream;

/// Interceptor Dio que:
///  1. Injeta "Authorization: Bearer <token>" em toda requisição.
///  2. Em 401/403: limpa a sessão local e notifica via authErrorStream.
class AuthInterceptor extends Interceptor {
  final SessionManager _session;
  AuthInterceptor(this._session);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _session.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    if (status == 401 || status == 403) {
      _session.clear(); // fire-and-forget — sessão será inválida de qualquer forma
      _authErrorController.add(null);
    }
    handler.next(err);
  }
}
