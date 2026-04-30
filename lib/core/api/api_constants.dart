class ApiConstants {
  ApiConstants._();

  // Configurar após receber documentação SYDLE
  static const String baseUrl = String.fromEnvironment(
    'SYDLE_BASE_URL',
    defaultValue: 'https://app.sydle.one/api',
  );

  // Endpoints — ajustar conforme documentação SYDLE ONE
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

  static const String employees = '/employees';
  static const String cycles = '/performance-cycles';
  static const String goals = '/goals';
  static const String evaluations = '/evaluations';
  static const String feedbacks = '/feedbacks';
  static const String meetings = '/executive-meetings';
  static const String promotions = '/promotions';
  static const String quotas = '/quota-program';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static const String contentType = 'application/json';
  static const String authHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
}