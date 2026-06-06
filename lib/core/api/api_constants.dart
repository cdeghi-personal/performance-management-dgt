class SydlePackage {
  SydlePackage._();

  static const String appDgt      = 'appDgt';
  static const String perfMngt    = 'perfMngt';
  static const String projetosDGT = 'projetosDGT';
}

class SydleClass {
  SydleClass._();

  // auth — package appDgt
  static const String authorization = 'authorization';

  // perfMngt — classes diretas
  static const String cycle            = 'cycle';
  static const String criterion        = 'criterion';
  static const String autoEvaluation   = 'autoEvaluation';
  static const String liderEvaluation  = 'leaderEvaluation';

  // projetosDGT — colaboradores
  static const String colaboradorDGT = 'colaboradorDGT';

  // perfMngt — perfil complementar do colaborador
  static const String employeeProfile = 'employeeProfile';

  // tabEvaluation e tabGoals são embedded — nunca chamados diretamente
}

class SydleMethod {
  SydleMethod._();

  static const String search = '_search';
  static const String get = '_get';
  static const String create = '_create';
  static const String update = '_update';
  static const String patch = '_patch';
  static const String delete = '_delete';
  static const String login = 'login';
}
