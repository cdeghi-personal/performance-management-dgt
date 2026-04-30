/// Pacotes e classes do SYDLE ONE.
/// Padrão de chamada: SydleClient.call(package, className, method, body)
class SydlePackage {
  SydlePackage._();

  static const String appDgt = 'appDgt';
  static const String hrm = 'hrm';         // gestão de pessoas
  static const String performance = 'performance'; // ciclos, metas, avaliações
}

class SydleClass {
  SydleClass._();

  // Auth
  static const String authorization = 'authorization';

  // Pessoas / funcionários
  static const String employee = 'employee';
  static const String person = 'person';

  // Performance
  static const String cycle = 'performanceCycle';
  static const String goal = 'goal';
  static const String keyResult = 'keyResult';
  static const String evaluation = 'evaluation';
  static const String feedback = 'feedback';
  static const String meeting = 'executiveMeeting';
  static const String promotion = 'promotionRequest';
  static const String quota = 'quotaProgram';
}

class SydleMethod {
  SydleMethod._();

  // Métodos padrão SYDLE
  static const String create = '_create';
  static const String update = '_update';
  static const String patch = '_patch';
  static const String search = '_search';
  static const String get = '_get';
  static const String delete = '_delete';

  // Métodos customizados — confirmar nomes reais com a equipe SYDLE
  static const String login = 'login';
  static const String getProfile = 'getProfile';
  static const String findByEmployee = 'findByEmployee';
  static const String findByCycle = 'findByCycle';
  static const String submitEvaluation = 'submitEvaluation';
  static const String approvePromotion = 'approvePromotion';
  static const String rejectPromotion = 'rejectPromotion';
}