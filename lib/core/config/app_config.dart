// Valores injetados via --dart-define no build/run. Nunca hardcodar aqui.
// Exemplo: flutter run --dart-define=SYDLE_ORG=dgt-consultoria-dev
class AppConfig {
  AppConfig._();

  static const String organization = String.fromEnvironment(
    'SYDLE_ORG',
    defaultValue: 'sydle',
  );

  /// Base para chamadas de negócio e autenticação.
  /// Formato: https://<org>.sydle.one/api/1/<identificadorDaAplicacao>
  /// O identificadorDaAplicacao é 'perfManagement' — deve estar configurado no org SYDLE.
  static String get baseUrl =>
      'https://$organization.sydle.one/api/1/perfManagement';

  static String get authBaseUrl =>
      'https://$organization.sydle.one/api/1/perfManagement';
}