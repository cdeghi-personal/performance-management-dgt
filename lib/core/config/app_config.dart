// Valores injetados via --dart-define no build/run. Nunca hardcodar aqui.
// Exemplo: flutter run --dart-define=SYDLE_ORG=sydle --dart-define=SYDLE_AUTH_TOKEN=Basic xxx
class AppConfig {
  AppConfig._();

  static const String organization = String.fromEnvironment(
    'SYDLE_ORG',
    defaultValue: 'sydle', // substituir pela org real da DGT
  );

  static String get baseUrl =>
      'https://$organization.sydle.one/api/1/main';

  // Basic <base64(usuario:senha)> da conta de serviço do app
  static const String authorizationToken = String.fromEnvironment(
    'SYDLE_AUTH_TOKEN',
    defaultValue: '', // obrigatório no build de produção
  );
}