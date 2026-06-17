import 'package:flutter_dotenv/flutter_dotenv.dart';

// Valores lidos do arquivo .env bundled com o app (via flutter_dotenv).
// Nunca hardcodar credenciais aqui — editar o .env (gitignored).
class AppConfig {
  AppConfig._();

  static String get organization => dotenv.env['SYDLE_ORG'] ?? 'sydle';

  static String get buildDate => dotenv.env['BUILD_DATE'] ?? 'dev';

  /// Base para chamadas de negócio e autenticação.
  /// Formato: https://<org>.sydle.one/api/1/<identificadorDaAplicacao>
  /// O identificadorDaAplicacao é 'perfManagement' — deve estar configurado no org SYDLE.
  static String get baseUrl =>
      'https://$organization.sydle.one/api/1/perfManagement';

  static String get authBaseUrl =>
      'https://$organization.sydle.one/api/1/perfManagement';
}
